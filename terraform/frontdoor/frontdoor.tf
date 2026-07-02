locals {
  tags = {
    project     = "s3"
    role        = "frontdoor"
    owner       = var.owner
    cost_center = var.cost_center
    keep_until  = var.keep_until
    managed_by  = "terraform"
  }
}

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "afd-s3"
  resource_group_name = data.terraform_remote_state.shared.outputs.shared_resource_group
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "endpoint-s3"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "app" {
  name                     = "og-app"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    path                = "/api/healthz"
    protocol            = "Https"
    request_type        = "GET"
    interval_in_seconds = 30
  }
}

# Primary (swedencentral) — priority 1.
resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                           = "origin-primary"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.app.id
  enabled                        = true
  host_name                      = var.primary_origin_host
  origin_host_header             = var.primary_origin_host
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# DR (polandcentral) — priority 2 (failover target).
resource "azurerm_cdn_frontdoor_origin" "dr" {
  name                           = "origin-dr"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.app.id
  enabled                        = true
  host_name                      = var.dr_origin_host
  origin_host_header             = var.dr_origin_host
  http_port                      = 80
  https_port                     = 443
  priority                       = 2
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "default" {
  name                          = "default-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.app.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.primary.id, azurerm_cdn_frontdoor_origin.dr.id]
  enabled                       = true
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]
  link_to_default_domain        = true
}

output "frontdoor_endpoint" {
  value = azurerm_cdn_frontdoor_endpoint.main.host_name
}
