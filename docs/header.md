# venky-terraform-module-eks

Terraform module for provisioning EKS clusters supporting both cloud and hybrid deployments.

## Features

- EKS cluster (cloud and hybrid/Outposts support)
- Managed node groups with configurable scaling, taints, and labels
- Remote network configuration for hybrid clusters
- Secrets encryption via KMS
- Control plane logging to CloudWatch
- EKS Access Entries (API-based RBAC)
- Configurable endpoint access (public/private)
- IPv4 and IPv6 support

## Usage - Cloud EKS

```hcl
module "eks" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git?ref=v0.1.0"

  name             = "platform-prod"
  cluster_version  = "1.30"
  cluster_role_arn = module.iam.role_arns["eks-cluster"]
  subnet_ids       = module.vpc.private_subnet_ids

  cluster_encryption_kms_key_arn = module.security.kms_key_arns["eks"]

  managed_node_groups = {
    general = {
      node_role_arn  = module.iam.role_arns["eks-node"]
      instance_types = ["m5.xlarge"]
      min_size       = 3
      max_size       = 20
      desired_size   = 5
    }
    spot = {
      node_role_arn  = module.iam.role_arns["eks-node"]
      instance_types = ["m5.large", "m5a.large", "m4.large"]
      capacity_type  = "SPOT"
      min_size       = 0
      max_size       = 50
      desired_size   = 5
      taints         = [{ key = "spot", effect = "NO_SCHEDULE" }]
    }
  }

  tags = { Environment = "prod", ManagedBy = "terraform" }
}
```

## Usage - Hybrid EKS

```hcl
module "eks" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git?ref=v0.1.0"

  name             = "hybrid-prod"
  cluster_version  = "1.30"
  cluster_role_arn = module.iam.role_arns["eks-cluster"]
  subnet_ids       = module.vpc.private_subnet_ids

  cluster_type = "hybrid"

  remote_network_config = {
    remote_node_cidrs = ["172.16.0.0/16"]
    remote_pod_cidrs  = ["172.17.0.0/16"]
  }

  tags = { Environment = "prod", ClusterType = "hybrid" }
}
```
