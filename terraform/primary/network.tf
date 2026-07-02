resource "azurerm_resource_group" "main" {
  name     = "rg-${local.base}"
  location = var.region
  tags     = local.tags

  lifecycle { ignore_changes = [tags["created_date"]] }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.base}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.vnet_cidr]
  tags                = local.tags

  lifecycle { ignore_changes = [tags["created_date"]] }
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)] # x.x.1.0/24
}

resource "azurerm_subnet" "pg" {
  name                 = "snet-pg"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 2)] # x.x.2.0/24

  delegation {
    name = "fs"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_zone" "pg" {
  name                = "${local.base}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  lifecycle { ignore_changes = [tags["created_date"]] }
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  name                  = "pdnslink-${local.base}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.pg.name
  virtual_network_id    = azurerm_virtual_network.main.id
  tags                  = local.tags

  lifecycle { ignore_changes = [tags["created_date"]] }
}
