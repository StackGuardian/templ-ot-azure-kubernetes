locals {
  tags = merge(
    {
      Project     = var.name_prefix
      Environment = "demo"
      ManagedBy   = "opentofu"
      Repository  = "tf-azure-kubernetes"
    },
    var.tags,
  )
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-aks-rg"
  location = var.location
  tags     = local.tags
}
