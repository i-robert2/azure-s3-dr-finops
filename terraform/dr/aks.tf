resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.base}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = "aks-${local.base}"
  sku_tier            = "Free"
  tags                = local.tags

  default_node_pool {
    name                 = "system"
    vm_size              = var.vm_size
    node_count           = 1
    vnet_subnet_id       = azurerm_subnet.aks.id
    orchestrator_version = null
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }

  lifecycle { ignore_changes = [tags["created_date"], default_node_pool[0].orchestrator_version, kubernetes_version] }
}

resource "azurerm_role_assignment" "aks_acrpull" {
  scope                            = data.terraform_remote_state.shared.outputs.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}
