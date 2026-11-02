# Helper for the integration test: reads the live state of the system node pool.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "node_pool_name" {
  type = string
}

data "azurerm_kubernetes_cluster_node_pool" "system" {
  name                    = var.node_pool_name
  kubernetes_cluster_name = var.cluster_name
  resource_group_name     = var.resource_group_name
}

output "node_count" {
  value = data.azurerm_kubernetes_cluster_node_pool.system.node_count
}

output "mode" {
  value = data.azurerm_kubernetes_cluster_node_pool.system.mode
}
