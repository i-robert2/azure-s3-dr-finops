resource "azurerm_resource_group" "shared" {
  name     = "rg-s3-shared"
  location = var.primary_region
  tags     = local.tags

  lifecycle { ignore_changes = [tags["created_date"]] }
}

resource "random_string" "acr" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

# Premium is required for geo-replication. One registry, a local replica
# in the DR region so each cluster pulls images from its own region.
resource "azurerm_container_registry" "main" {
  name                = "acrs3dev${random_string.acr.result}"
  resource_group_name = azurerm_resource_group.shared.name
  location            = var.primary_region
  sku                 = "Premium"
  admin_enabled       = false
  tags                = local.tags

  georeplications {
    location                = var.dr_region
    zone_redundancy_enabled = false
    tags                    = local.tags
  }

  lifecycle { ignore_changes = [tags["created_date"], georeplications[0].tags["created_date"]] }
}
