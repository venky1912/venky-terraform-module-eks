# venky-terraform-module-eks

Terraform module for provisioning EKS clusters supporting both cloud and hybrid deployments.

## Features

- EKS cluster (cloud and hybrid support)
- Managed node groups with configurable scaling, taints, and labels
- **Hybrid node role submodule** (SSM-based on-prem node registration)
- Remote network configuration for hybrid clusters
- HYBRID_LINUX access entry for on-prem nodes
- Secrets encryption via KMS
- Control plane logging to CloudWatch
- EKS Access Entries (API-based RBAC)
- Configurable endpoint access (public/private)

## Submodules

### `modules/hybrid-node-role`

Creates the IAM role and SSM activation needed for on-premises nodes to join the cluster:

```hcl
module "hybrid_node_role" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git//modules/hybrid-node-role?ref=v0.2.0"

  cluster_name           = "my-cluster"
  ssm_registration_limit = 50

  tags = { Environment = "prod" }
}
```

## Usage - Cloud EKS

```hcl
module "eks" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git?ref=v0.2.0"

  name             = "platform-prod"
  cluster_version  = "1.30"
  cluster_role_arn = module.iam.role_arns["eks-cluster"]
  subnet_ids       = module.vpc.private_subnet_ids
  cluster_type     = "cloud"

  managed_node_groups = {
    general = {
      node_role_arn  = module.iam.role_arns["eks-node"]
      instance_types = ["m5.xlarge"]
      min_size       = 3
      max_size       = 20
      desired_size   = 5
    }
  }

  tags = { Environment = "prod", ManagedBy = "terraform" }
}
```

## Usage - Hybrid EKS (On-Prem Nodes)

```hcl
module "hybrid_node_role" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git//modules/hybrid-node-role?ref=v0.2.0"

  cluster_name           = "platform-hybrid"
  ssm_registration_limit = 100
  tags                   = { Environment = "prod" }
}

module "eks" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git?ref=v0.2.0"

  name             = "platform-hybrid"
  cluster_version  = "1.30"
  cluster_role_arn = module.iam.role_arns["eks-cluster"]
  subnet_ids       = module.vpc.private_subnet_ids
  cluster_type     = "hybrid"

  remote_network_config = {
    remote_node_cidrs = ["172.16.0.0/16"]
    remote_pod_cidrs  = ["172.17.0.0/16"]
  }

  hybrid_node_role_arn = module.hybrid_node_role.role_arn

  tags = { Environment = "prod", ClusterType = "hybrid" }
}
```
