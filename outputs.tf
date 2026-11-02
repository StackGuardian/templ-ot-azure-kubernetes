output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "cluster_fqdn" {
  description = "FQDN of the Kubernetes API server"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kubernetes_version" {
  description = "Running Kubernetes version"
  value       = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity federation"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_pool_name" {
  description = "Name of the system node pool"
  value       = azurerm_kubernetes_cluster.this.default_node_pool[0].name
}

output "kubeconfig_command" {
  description = "Commands to add the cluster to your kubeconfig with Entra ID login"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name} && kubelogin convert-kubeconfig -l azurecli"
}
