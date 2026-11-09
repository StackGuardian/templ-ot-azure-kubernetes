resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.advanced_settings.vnet_cidr]
  tags                = local.tags
}

# Nodes only. Pods get IPs from the overlay pod CIDR.
resource "azurerm_subnet" "nodes" {
  name                            = "nodes"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [cidrsubnet(var.advanced_settings.vnet_cidr, 4, 0)]
  default_outbound_access_enabled = false
}

# Default rules only: traffic inside the VNet and from Azure load balancers.
# Add inbound rules here if you expose a LoadBalancer service to the internet.
resource "azurerm_network_security_group" "nodes" {
  name                = "${var.name_prefix}-nodes-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "nodes" {
  subnet_id                 = azurerm_subnet.nodes.id
  network_security_group_id = azurerm_network_security_group.nodes.id
}
