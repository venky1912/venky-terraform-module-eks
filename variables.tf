################################################################################
# General
################################################################################

variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Cluster
################################################################################

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster control plane"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Additional security group IDs for the cluster"
  type        = list(string)
  default     = []
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to cluster API endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster API endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed for public API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_encryption_kms_key_arn" {
  description = "ARN of KMS key to encrypt Kubernetes secrets"
  type        = string
  default     = null
}

variable "cluster_enabled_log_types" {
  description = "EKS control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch log group retention for EKS control plane logs"
  type        = number
  default     = 90
}

################################################################################
# Cluster Type (Cloud vs Hybrid)
################################################################################

variable "cluster_type" {
  description = "Type of EKS cluster: 'cloud' or 'hybrid'"
  type        = string
  default     = "cloud"

  validation {
    condition     = contains(["cloud", "hybrid"], var.cluster_type)
    error_message = "cluster_type must be 'cloud' or 'hybrid'."
  }
}

variable "outpost_arns" {
  description = "ARNs of AWS Outposts for hybrid cluster deployment"
  type        = list(string)
  default     = []
}

variable "outpost_control_plane_instance_type" {
  description = "Instance type for EKS control plane on Outposts (e.g., m5.large)"
  type        = string
  default     = "m5.large"
}

variable "remote_network_config" {
  description = "Remote network configuration for hybrid clusters"
  type = object({
    remote_node_cidrs = optional(list(string), [])
    remote_pod_cidrs  = optional(list(string), [])
  })
  default = null
}

################################################################################
# Networking
################################################################################

variable "service_ipv4_cidr" {
  description = "CIDR block for Kubernetes service IPs"
  type        = string
  default     = null
}

variable "ip_family" {
  description = "IP family for the cluster (ipv4 or ipv6)"
  type        = string
  default     = "ipv4"
}

################################################################################
# Node Groups (Managed)
################################################################################

variable "managed_node_groups" {
  description = <<-EOT
    Map of managed node group configurations.
    Example:
    {
      general = {
        instance_types = ["m5.large"]
        min_size       = 2
        max_size       = 10
        desired_size   = 3
        disk_size      = 50
        capacity_type  = "ON_DEMAND"
      }
    }
  EOT
  type = map(object({
    node_role_arn  = string
    instance_types = optional(list(string), ["m5.large"])
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    min_size       = optional(number, 1)
    max_size       = optional(number, 5)
    desired_size   = optional(number, 2)
    subnet_ids     = optional(list(string))
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Access Config
################################################################################

variable "authentication_mode" {
  description = "Authentication mode for the cluster (API, CONFIG_MAP, or API_AND_CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "access_entries" {
  description = <<-EOT
    Map of access entries for EKS cluster access.
    Example:
    {
      admin = {
        principal_arn = "arn:aws:iam::123456789:role/admin"
        type          = "STANDARD"
        policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope  = { type = "cluster" }
      }
    }
  EOT
  type = map(object({
    principal_arn = string
    type          = optional(string, "STANDARD")
    policy_arn    = optional(string, "")
    access_scope = optional(object({
      type       = string
      namespaces = optional(list(string))
    }), { type = "cluster" })
  }))
  default = {}
}

################################################################################
# Hybrid Node Config
################################################################################

variable "hybrid_node_role_arn" {
  description = "ARN of the hybrid node IAM role (from modules/hybrid-node-role). Creates HYBRID_LINUX access entry."
  type        = string
  default     = null
}
