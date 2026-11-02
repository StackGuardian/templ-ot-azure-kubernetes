resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.name_prefix}-aks-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  #checkov:skip=CKV_AZURE_6:Authorized IP ranges come from allowed_api_cidrs, a validation requires at least one
  #checkov:skip=CKV_AZURE_232:Single system node pool for the demo, workloads run on it too
  #checkov:skip=CKV_AZURE_115:Public API server limited to allowed_api_cidrs, a private cluster would need a jump host
  #checkov:skip=CKV_AZURE_117:Disks use platform-managed keys, a disk encryption set is out of scope for the demo
  #checkov:skip=CKV_AZURE_170:Free tier for the demo, the paid SLA tier is not needed
  #checkov:skip=CKV_AZURE_226:Ephemeral OS disks need VM sizes with a local cache disk
  #checkov:skip=CKV_AZURE_227:Host encryption is configurable via host_encryption_enabled
  name                      = "${var.name_prefix}-aks"
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_prefix                = "${var.name_prefix}-aks"
  kubernetes_version        = var.kubernetes_version
  sku_tier                  = "Free"
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  local_account_disabled            = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true
  tags                              = local.tags

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  api_server_access_profile {
    authorized_ip_ranges = var.allowed_api_cidrs
  }

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    node_count                  = var.node_count
    vnet_subnet_id              = azurerm_subnet.nodes.id
    max_pods                    = 50
    host_encryption_enabled     = var.host_encryption_enabled
    node_public_ip_enabled      = false
    temporary_name_for_rotation = "systemtmp"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Node pools are managed here, not by node auto provisioning.
  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    load_balancer_sku   = "standard"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.this.id
    msi_auth_for_monitoring_enabled = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  depends_on = [azurerm_subnet_network_security_group_association.nodes]
}

# Cluster admin for the identity that runs OpenTofu (Entra ID + Azure RBAC)
resource "azurerm_role_assignment" "deployer_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "audit"
  target_resource_id         = azurerm_kubernetes_cluster.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "guard"
  }
}
