variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the hybrid node role"
  type        = map(string)
  default     = {}
}

variable "create_ssm_activation" {
  description = "Whether to create an SSM hybrid activation for on-prem nodes"
  type        = bool
  default     = true
}

variable "ssm_registration_limit" {
  description = "Maximum number of on-prem nodes allowed to register"
  type        = number
  default     = 100
}

variable "ssm_activation_expiry" {
  description = "Expiration date for SSM activation (RFC3339 format, e.g., 2027-01-01T00:00:00Z)"
  type        = string
  default     = "2027-12-31T23:59:59Z"
}
