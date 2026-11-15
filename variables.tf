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

variable "allowed_api_cidrs" {
  description = "IPv4 CIDRs allowed to reach the Kubernetes API server"
  type        = list(string)

  validation {
    condition     = length(var.allowed_api_cidrs) > 0 && alltrue([for c in var.allowed_api_cidrs : can(cidrnetmask(c))])
    error_message = "Set at least one valid IPv4 CIDR block."
  }

  validation {
    condition     = alltrue([for c in var.allowed_api_cidrs : try(tonumber(split("/", c)[1]) >= 8, false)])
    error_message = "CIDRs broader than /8, such as 0.0.0.0/0, are not allowed."
  }
}

# Grouped so the StackGuardian form can show them in one "Advanced Settings" section.
variable "advanced_settings" {
  description = "Settings most deployments keep at their defaults"
  type = object({
    vnet_cidr               = optional(string, "10.0.0.0/16")     # Address space of the VNet. Must not overlap with the pod and service CIDRs.
    kubernetes_version      = optional(string, "1.37")            # Kubernetes minor version; AKS picks the latest patch
    node_vm_size            = optional(string, "Standard_D2s_v5") # VM size of the system node pool
    node_count              = optional(number, 2)                 # Number of nodes in the system node pool
    host_encryption_enabled = optional(bool, false)               # Needs the EncryptionAtHost feature registered in the subscription
    log_retention_days      = optional(number, 90)                # Retention of the logs in Log Analytics
    tags                    = optional(map(string), {})           # Additional tags for all resources
  })
  default  = {}
  nullable = false

  validation {
    condition     = can(cidrnetmask(var.advanced_settings.vnet_cidr))
    error_message = "vnet_cidr must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = var.advanced_settings.node_count >= 2 && var.advanced_settings.node_count <= 19
    error_message = "node_count must be between 2 and 19."
  }

  validation {
    condition     = var.advanced_settings.log_retention_days >= 30 && var.advanced_settings.log_retention_days <= 730
    error_message = "Log Analytics retention must be between 30 and 730 days."
  }
}
