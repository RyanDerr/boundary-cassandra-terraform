#!/bin/bash

# Create log file for debugging
echo "Starting Boundary worker setup at $(date)" > /tmp/boundary-setup.log

# Update system
sudo apt update && sudo apt upgrade -y

# Install necessary packages
sudo apt install -y curl unzip jq

# Create boundary user
sudo useradd --system --home /etc/boundary.d --shell /bin/false boundary

# Download and install Boundary Enterprise
BOUNDARY_VERSION="${boundary_version}"
cd /tmp
curl -LO "https://releases.hashicorp.com/boundary/$${BOUNDARY_VERSION}+ent/boundary_$${BOUNDARY_VERSION}+ent_linux_amd64.zip"
unzip "boundary_$${BOUNDARY_VERSION}+ent_linux_amd64.zip"
sudo mv boundary /usr/local/bin/
sudo chmod +x /usr/local/bin/boundary

# Create Boundary directories
sudo mkdir -p /etc/boundary.d
sudo mkdir -p /var/lib/boundary
sudo chown boundary:boundary /var/lib/boundary

# Generate worker tags configuration
WORKER_TAGS_JSON='${worker_tags}'
echo "Processing worker tags JSON: $WORKER_TAGS_JSON" >> /tmp/boundary-setup.log

# Convert JSON to HCL format using jq
WORKER_TAGS_HCL=$(echo "$WORKER_TAGS_JSON" | jq -r 'to_entries | map("    \(.key) = \(.value)") | join("\n")' 2>/dev/null || echo "    type = [\"worker\", \"upstream\"]")

echo "Converted worker tags HCL: $WORKER_TAGS_HCL" >> /tmp/boundary-setup.log

# Add region tag dynamically
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
if [ ! -z "$REGION" ]; then
    WORKER_TAGS_HCL="$WORKER_TAGS_HCL"$'\n'"    region = [\"$REGION\"]"
fi

echo "Final worker tags HCL:" >> /tmp/boundary-setup.log
echo "$WORKER_TAGS_HCL" >> /tmp/boundary-setup.log

# Create Boundary worker configuration for controller-led activation
echo "Creating Boundary worker configuration..." >> /tmp/boundary-setup.log

sudo tee /etc/boundary.d/boundary-worker.hcl > /dev/null <<EOF
disable_mlock = true

hcp_boundary_cluster_id = "${boundary_hcp_cluster_id}"

listener "tcp" {
  address = "0.0.0.0:9202"
  purpose = "proxy"
}

worker {
  public_addr = "$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
  auth_storage_path = "/var/lib/boundary"
  controller_generated_activation_token = "${controller_generated_activation_token}"
  tags {
$WORKER_TAGS_HCL
  }
}
EOF

echo "Boundary worker configuration created:" >> /tmp/boundary-setup.log
cat /etc/boundary.d/boundary-worker.hcl >> /tmp/boundary-setup.log

# Set proper ownership
sudo chown -R boundary:boundary /etc/boundary.d

# Create systemd service
sudo tee /etc/systemd/system/boundary-worker.service > /dev/null <<EOF
[Unit]
Description=Boundary Worker
Documentation=https://www.boundaryproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/boundary.d/boundary-worker.hcl

[Service]
Type=notify
User=boundary
Group=boundary
ExecStart=/usr/local/bin/boundary server -config=/etc/boundary.d/boundary-worker.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable boundary-worker
sudo systemctl start boundary-worker

echo "Boundary worker service started" >> /tmp/boundary-setup.log
echo "Service status:" >> /tmp/boundary-setup.log
systemctl status boundary-worker >> /tmp/boundary-setup.log 2>&1

echo "Boundary worker configured with controller-led activation and started successfully."
echo "Setup completed at $(date)" >> /tmp/boundary-setup.log
echo "Check /tmp/boundary-setup.log for detailed setup information" >> /tmp/boundary-setup.log