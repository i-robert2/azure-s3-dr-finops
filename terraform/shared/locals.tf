locals {
  project = "s3"

  tags = {
    project      = local.project
    environment  = var.environment
    owner        = var.owner
    cost_center  = var.cost_center
    keep_until   = var.keep_until
    managed_by   = "terraform"
    created_date = timestamp()
  }
}
