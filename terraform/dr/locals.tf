locals {
  base = "s3-${var.environment}-${var.region_short}-${var.instance}"

  tags = {
    project      = "s3"
    environment  = var.environment
    region       = var.region
    role         = "dr"
    owner        = var.owner
    cost_center  = var.cost_center
    keep_until   = var.keep_until
    managed_by   = "terraform"
    created_date = timestamp()
  }
}
