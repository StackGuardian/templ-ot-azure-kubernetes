variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.name_prefix))
    error_message = "Use 2-16 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "location" {
  description = "Azure location"
  type        = string
  default     = "germanywestcentral"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "vnet_cidr" {
  description = "Address space of the VNet. Must not overlap with the pod and service CIDRs."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vnet_cidr))
    error_message = "Must be a valid IPv4 CIDR block."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version of the cluster. Null uses the current AKS default."
  type        = string
  default     = null
}

variable "allowed_api_cidrs" {
  description = "IPv4 CIDRs allowed to reach the Kubernetes API server"
  type        = list(string)

  validation {
    condition     = length(var.allowed_api_cidrs) > 0 && alltrue([for c in var.allowed_api_cidrs : can(cidrnetmask(c))])
    error_message = "Set at least one valid IPv4 CIDR block."
  }

  validation {
    condition     = !anytrue([for c in var.allowed_api_cidrs : endswith(c, "/0")])
    error_message = "Open-to-the-internet CIDRs like 0.0.0.0/0 are not allowed."
  }
}

variable "node_vm_size" {
  description = "VM size of the system node pool"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 2
}

variable "host_encryption_enabled" {
  description = "Encrypt temp disks and caches on the host. Needs the EncryptionAtHost feature registered in the subscription."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Retention of the logs in Log Analytics"
  type        = number
  default     = 90
}
