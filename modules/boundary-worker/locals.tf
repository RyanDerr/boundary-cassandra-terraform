# Local variables to ensure required tags are always present
locals {
  # Ensure worker and upstream are always included in type tags
  base_type_tags = ["worker", "upstream"]
  
  # Merge user-provided tags with required tags
  merged_worker_tags = merge(var.worker_tags, {
    type = distinct(concat(
      lookup(var.worker_tags, "type", []),
      local.base_type_tags
    ))
  })
}