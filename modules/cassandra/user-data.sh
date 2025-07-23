#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install Java and required packages
sudo apt-get install -y openjdk-11-jdk curl wget python3 python3-yaml

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' | sudo tee -a /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Create cassandra user
sudo useradd --system --home /opt/cassandra --shell /bin/bash cassandra

# Download and install Cassandra
cd /tmp
curl -OL https://dlcdn.apache.org/cassandra/5.0.4/apache-cassandra-5.0.4-bin.tar.gz
tar xzvf apache-cassandra-5.0.4-bin.tar.gz

# Move to /opt and set ownership
sudo mv apache-cassandra-5.0.4 /opt/cassandra
sudo chown -R cassandra:cassandra /opt/cassandra

# Create data and log directories
sudo mkdir -p /var/lib/cassandra/data
sudo mkdir -p /var/lib/cassandra/commitlog
sudo mkdir -p /var/lib/cassandra/saved_caches
sudo mkdir -p /var/log/cassandra
sudo chown -R cassandra:cassandra /var/lib/cassandra
sudo chown -R cassandra:cassandra /var/log/cassandra

# Get IP addresses
PRIVATE_IP=$(hostname -I | awk '{print $1}')
echo "Using private IP ($PRIVATE_IP) for both listen_address and broadcast_rpc_address"

# Configure Cassandra
sudo -u cassandra cp /opt/cassandra/conf/cassandra.yaml /opt/cassandra/conf/cassandra.yaml.backup

# Update specific Cassandra configuration attributes
CASSANDRA_CONF="/opt/cassandra/conf/cassandra.yaml"

# Update cluster_name
sudo -u cassandra sed -i "s/^cluster_name:.*/cluster_name: '${cluster_name}'/" $CASSANDRA_CONF

# Update authenticator
sudo -u cassandra sed -i "s/^authenticator:.*/authenticator: PasswordAuthenticator/" $CASSANDRA_CONF

# Update authorizer
sudo -u cassandra sed -i "s/^authorizer:.*/authorizer: CassandraAuthorizer/" $CASSANDRA_CONF

# Update listen_address
sudo -u cassandra sed -i "s/^listen_address:.*/listen_address: $PRIVATE_IP/" $CASSANDRA_CONF

# Update rpc_address
sudo -u cassandra sed -i "s/^rpc_address:.*/rpc_address: 0.0.0.0/" $CASSANDRA_CONF

# Add broadcast_rpc_address (append since it's commented out by default)
sudo -u cassandra sh -c "echo 'broadcast_rpc_address: $PRIVATE_IP' >> $CASSANDRA_CONF"

# Update seed_provider - this is more complex due to the YAML structure
sudo -u cassandra sed -i "/^seed_provider:/,/seeds:/ {
    /seeds:/ s/.*/          - seeds: \"$PRIVATE_IP\"/
}" $CASSANDRA_CONF

# Ensure data directories are set correctly
sudo -u cassandra sed -i "/^data_file_directories:/,/^[[:space:]]*-/ {
    /^[[:space:]]*-/ c\\    - /var/lib/cassandra/data
}" $CASSANDRA_CONF

# Ensure commitlog directory is set
sudo -u cassandra sed -i "s|^commitlog_directory:.*|commitlog_directory: /var/lib/cassandra/commitlog|" $CASSANDRA_CONF

# Ensure saved_caches directory is set
sudo -u cassandra sed -i "s|^saved_caches_directory:.*|saved_caches_directory: /var/lib/cassandra/saved_caches|" $CASSANDRA_CONF

# Validate YAML configuration before proceeding
echo "Validating Cassandra configuration..."
if ! python3 -c "import yaml; yaml.safe_load(open('$CASSANDRA_CONF'))" 2>/dev/null; then
    echo "ERROR: Invalid YAML configuration detected. Restoring backup..."
    sudo -u cassandra cp /opt/cassandra/conf/cassandra.yaml.backup $CASSANDRA_CONF
    echo "Configuration restored from backup. Please check the script for errors."
    exit 1
fi
echo "Configuration validation successful."

# Set up environment for cassandra user
sudo -u cassandra tee /opt/cassandra/.bashrc > /dev/null <<EOF
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export CASSANDRA_HOME=/opt/cassandra
export PATH=\$PATH:\$CASSANDRA_HOME/bin
EOF

# Create directory for PID file with proper permissions
sudo mkdir -p /run/cassandra
sudo chown cassandra:cassandra /run/cassandra

# Create systemd service
sudo tee /etc/systemd/system/cassandra.service > /dev/null <<EOF
[Unit]
Description=Apache Cassandra
After=network.target

[Service]
Type=forking
User=cassandra
Group=cassandra
RuntimeDirectory=cassandra
ExecStart=/opt/cassandra/bin/cassandra -p /run/cassandra/cassandra.pid
ExecStop=/bin/kill -TERM \$MAINPID
PIDFile=/run/cassandra/cassandra.pid
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=CASSANDRA_HOME=/opt/cassandra
Restart=on-failure
RestartSec=5
LimitNOFILE=100000
LimitMEMLOCK=infinity
LimitNPROC=32768
LimitAS=infinity

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Cassandra
sudo systemctl daemon-reload
sudo systemctl enable cassandra
sudo systemctl start cassandra

# Wait for Cassandra to start
echo "Waiting for Cassandra to start..."
sleep 30

# Check if Cassandra is running
for i in {1..30}; do
    if sudo -u cassandra /opt/cassandra/bin/nodetool status >/dev/null 2>&1; then
        echo "Cassandra is running!"
        break
    fi
    echo "Waiting for Cassandra to be ready... ($i/30)"
    sleep 10
done

# Output connection information
echo "========================================="
echo "Cassandra Installation Complete"
echo "========================================="
echo "Private IP: $PRIVATE_IP"
echo "Cassandra CQL Port: 9042"
echo "Cluster Name: ${cluster_name}"
echo "========================================="
echo "To check status: sudo systemctl status cassandra"
echo "To check logs: sudo journalctl -u cassandra -f"
echo "To connect via cqlsh: sudo -u cassandra /opt/cassandra/bin/cqlsh $PRIVATE_IP"
echo "========================================="