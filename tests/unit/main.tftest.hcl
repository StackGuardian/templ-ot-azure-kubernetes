# Unit tests: plan only, providers are mocked. No cloud account, no cost.
# Run: tofu test -test-directory=tests/unit
# Test case catalog: tests/README.md

# Some arguments are validated as Azure resource IDs or UUIDs, so mocked values must look real.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
      object_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-subnet"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/networkSecurityGroups/mock-nsg"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-law"
    }
  }

  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.ContainerService/managedClusters/mock-aks"
    }
  }
}

variables {
  allowed_api_cidrs = ["203.0.113.0/24"]
}

# U-01
run "defaults_are_valid" {
  command = plan

  assert {
    condition = (
      local.tags["Environment"] == "demo" &&
      local.tags["ManagedBy"] == "opentofu" &&
      local.tags["Project"] == var.name_prefix &&
      local.tags["Repository"] != ""
    )
    error_message = "Default tags are missing or wrong."
  }
}

# U-02
run "invalid_name_prefix_is_rejected" {
  command = plan

  variables {
    name_prefix = "Invalid_Prefix"
  }

  expect_failures = [var.name_prefix]
}

# U-03
run "custom_tags_are_merged" {
  command = plan

  variables {
    advanced_settings = {
      tags = {
        Owner = "tester"
      }
    }
  }

  assert {
    condition     = local.tags["Owner"] == "tester" && local.tags["ManagedBy"] == "opentofu"
    error_message = "Custom tags are not merged with the default tags."
  }
}

# U-04
run "api_server_is_restricted" {
  command = apply

  assert {
    condition     = toset(one(azurerm_kubernetes_cluster.this.api_server_access_profile).authorized_ip_ranges) == toset(["203.0.113.0/24"])
    error_message = "The API server must be limited to allowed_api_cidrs."
  }
}

# U-05
run "open_api_cidr_is_rejected" {
  command = plan

  variables {
    allowed_api_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.allowed_api_cidrs]
}

# U-06
run "entra_id_and_azure_rbac" {
  command = apply

  assert {
    condition     = azurerm_kubernetes_cluster.this.local_account_disabled
    error_message = "Local accounts must be disabled."
  }

  assert {
    condition = (
      one(azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control).azure_rbac_enabled &&
      one(azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control).tenant_id == "00000000-0000-0000-0000-000000000001"
    )
    error_message = "Entra ID integration with Azure RBAC must be enabled."
  }
}

# U-07
run "workload_identity_is_enabled" {
  command = apply

  assert {
    condition     = azurerm_kubernetes_cluster.this.oidc_issuer_enabled && azurerm_kubernetes_cluster.this.workload_identity_enabled
    error_message = "OIDC issuer and workload identity must be enabled."
  }
}

# U-08
run "policy_and_monitoring_are_enabled" {
  command = apply

  assert {
    condition     = azurerm_kubernetes_cluster.this.azure_policy_enabled
    error_message = "The Azure Policy add-on must be enabled."
  }

  assert {
    condition     = one(azurerm_kubernetes_cluster.this.oms_agent).log_analytics_workspace_id == azurerm_log_analytics_workspace.this.id
    error_message = "Container Insights must send data to the Log Analytics workspace."
  }

  assert {
    condition     = contains([for l in azurerm_monitor_diagnostic_setting.aks.enabled_log : l.category], "kube-audit-admin")
    error_message = "Kubernetes audit logs must be sent to Log Analytics."
  }
}

# U-09
run "deployer_is_cluster_admin" {
  command = apply

  assert {
    condition = (
      azurerm_role_assignment.deployer_cluster_admin.scope == azurerm_kubernetes_cluster.this.id &&
      azurerm_role_assignment.deployer_cluster_admin.role_definition_name == "Azure Kubernetes Service RBAC Cluster Admin" &&
      azurerm_role_assignment.deployer_cluster_admin.principal_id == "00000000-0000-0000-0000-000000000002"
    )
    error_message = "The deploying identity must get the AKS RBAC Cluster Admin role on the cluster."
  }
}

# U-10
run "nodes_are_private" {
  command = apply

  assert {
    condition = (
      !one(azurerm_kubernetes_cluster.this.default_node_pool).node_public_ip_enabled &&
      one(azurerm_kubernetes_cluster.this.default_node_pool).vnet_subnet_id == azurerm_subnet.nodes.id
    )
    error_message = "Nodes must be in the node subnet without public IPs."
  }

  assert {
    condition     = azurerm_subnet_network_security_group_association.nodes.subnet_id == azurerm_subnet.nodes.id
    error_message = "The node subnet must have an NSG."
  }

  assert {
    condition     = one(azurerm_kubernetes_cluster.this.network_profile).network_policy == "cilium"
    error_message = "A network policy engine must be enabled."
  }
}

# U-11
run "broad_api_cidr_is_rejected" {
  command = plan

  variables {
    allowed_api_cidrs = ["128.0.0.0/1"]
  }

  expect_failures = [var.allowed_api_cidrs]
}
