# Azure Kubernetes Cluster (AKS)

Creates an Azure Kubernetes Service cluster with Entra ID sign-in and one system node pool. No application is deployed, so the cluster is ready for your own workloads.

Use it to show a hardened Kubernetes setup on Azure or to get a cluster for tests.

## What gets created

- A resource group
- A virtual network with a node subnet and a network security group
- The AKS cluster (Free tier) with one system node pool, Azure CNI Overlay with Cilium
- A Log Analytics workspace for Container Insights and audit logs (the name ends with a random suffix, because Azure reserves the name of a deleted workspace for 14 days)
- Cluster admin rights for the identity that runs the deployment

## Before you start

- A workflow with an Azure cloud connector for the target subscription
- The connector's identity needs rights to create resources **and** to assign roles (for example Owner, or Contributor plus User Access Administrator)
- The public IP range you work from, for **Allowed api cidrs**
- To use the cluster from your own machine: the Azure CLI, `kubectl`, `kubelogin` and an AKS RBAC role on the cluster for your Entra ID user (see "After the run")
- Optional: the EncryptionAtHost feature registered in the subscription, if you want host encryption

## Form fields

| Field | What it does | Default |
|---|---|---|
| Allowed api cidrs | **Required.** IP ranges that may reach the Kubernetes API, for example your office or VPN address. `0.0.0.0/0` is rejected | none |
| Name prefix | Prefix for all resource names. 2 to 16 lowercase letters, digits or hyphens, starting with a letter | `demo` |
| Location | Azure region | Germany West Central |

**Advanced Settings** (tick "Show advanced settings" to change them):

| Field | What it does | Default |
|---|---|---|
| VNet cidr | IP range of the new network. Must not overlap with `192.168.0.0/16` (pods) and `172.16.0.0/16` (services) | `10.0.0.0/16` |
| Kubernetes version | Kubernetes version. AKS picks the latest patch | `1.37` |
| Node vm size | Size of each node | D2s v5 (2 vCPU, 8 GiB) |
| Node count | Number of nodes, 2 to 19 | `2` |
| Host encryption enabled | Also encrypts temp disks and caches on the host. Needs the subscription feature | off |
| Log retention days | How long logs are kept | `90` |
| Tags | Extra tags added to all resources | none |

The version list contains the AKS versions in standard support. A new version may not be available in every region yet. If the run fails for that reason on a new cluster, pick the next lower version. On an existing cluster, AKS upgrades one minor version at a time (for example 1.35, then 1.36), so 1.35 to 1.37 in one step is not allowed, and it cannot go back to an older version. Change the version in single steps and never to a lower one.

## After the run

The workflow outputs show:

- `cluster_name`, `resource_group_name` and `kubernetes_version`
- `kubeconfig_command`: adds the cluster to your kubeconfig. Local accounts are off, so `kubectl` works only for an Entra ID user with an AKS RBAC role on the cluster, from an allowed IP
- `oidc_issuer_url`: for workload identity

The only cluster admin at the start is the identity that ran the deployment, which is the identity of the StackGuardian cloud connector. Workflows that use the same connector can manage the cluster. Subscription Owner or Contributor does not give access to the cluster itself: to use `kubectl` yourself or to give other people access, assign an AKS RBAC role on the cluster (for example "Azure Kubernetes Service RBAC Cluster Admin"). Creating the cluster takes about 10 minutes.

## Security defaults

- Sign-in only with Entra ID and Azure RBAC. Local accounts are disabled
- The API is reachable only from the allowed IP ranges
- Nodes have no public IPs. Cilium network policies are available
- Workload identity, Azure Policy and the Key Vault secrets provider are enabled
- Automatic patch upgrades for Kubernetes and node images
- Container Insights and audit logs go to Log Analytics

## Cost and cleanup

The nodes, the load balancer and log ingestion are billed, also when idle. The Free tier has no control plane fee. Destroy the resources from the workflow when the demo is over.

## Limits

- One system node pool, no extra user node pool
- No sample workload. To expose a `LoadBalancer` service to the internet, add an inbound rule to the node subnet's security group
