module "eks" {
  source = "../../"

  name             = "platform-dev"
  cluster_version  = "1.30"
  cluster_role_arn = "arn:aws:iam::123456789012:role/platform-dev-eks-cluster"
  subnet_ids       = ["subnet-111", "subnet-222", "subnet-333"]

  cluster_type = "cloud"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_enabled_log_types  = ["api", "audit", "authenticator"]
  cluster_log_retention_days = 30

  authentication_mode = "API_AND_CONFIG_MAP"

  managed_node_groups = {
    general = {
      node_role_arn  = "arn:aws:iam::123456789012:role/platform-dev-eks-node"
      instance_types = ["m5.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels         = { workload = "general" }
    }
  }

  access_entries = {}

  tags = {
    Environment = "dev"
    Project     = "eks-platform"
    ManagedBy   = "terraform"
  }
}
