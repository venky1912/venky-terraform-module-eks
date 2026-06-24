<!-- BEGIN_TF_DOCS -->
# venky-terraform-module-eks

Terraform module for provisioning EKS clusters supporting both cloud and hybrid deployments.

## Features

- EKS cluster (cloud and hybrid support)
- Managed node groups with configurable scaling, taints, and labels
- **Hybrid node role submodule** (SSM-based on-prem node registration)
- Remote network configuration for hybrid clusters
- HYBRID\_LINUX access entry for on-prem nodes
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

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0, < 7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_access_entry.hybrid_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_entry.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_role_arn"></a> [cluster\_role\_arn](#input\_cluster\_role\_arn) | ARN of the IAM role for the EKS cluster | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for the EKS cluster control plane | `list(string)` | n/a | yes |
| <a name="input_access_entries"></a> [access\_entries](#input\_access\_entries) | Map of access entries for EKS cluster access.<br/>Example:<br/>{<br/>  admin = {<br/>    principal\_arn = "arn:aws:iam::123456789:role/admin"<br/>    type          = "STANDARD"<br/>    policy\_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"<br/>    access\_scope  = { type = "cluster" }<br/>  }<br/>} | <pre>map(object({<br/>    principal_arn = string<br/>    type          = optional(string, "STANDARD")<br/>    policy_arn    = optional(string, "")<br/>    access_scope = optional(object({<br/>      type       = string<br/>      namespaces = optional(list(string))<br/>    }), { type = "cluster" })<br/>  }))</pre> | `{}` | no |
| <a name="input_authentication_mode"></a> [authentication\_mode](#input\_authentication\_mode) | Authentication mode for the cluster (API, CONFIG\_MAP, or API\_AND\_CONFIG\_MAP) | `string` | `"API_AND_CONFIG_MAP"` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | EKS control plane log types to enable | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_cluster_encryption_kms_key_arn"></a> [cluster\_encryption\_kms\_key\_arn](#input\_cluster\_encryption\_kms\_key\_arn) | ARN of KMS key to encrypt Kubernetes secrets | `string` | `null` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Enable private access to cluster API endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable public access to cluster API endpoint | `bool` | `false` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | CIDR blocks allowed for public API access | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cluster_log_retention_days"></a> [cluster\_log\_retention\_days](#input\_cluster\_log\_retention\_days) | CloudWatch log group retention for EKS control plane logs | `number` | `90` | no |
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | Type of EKS cluster: 'cloud' or 'hybrid' | `string` | `"cloud"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.30"` | no |
| <a name="input_hybrid_node_role_arn"></a> [hybrid\_node\_role\_arn](#input\_hybrid\_node\_role\_arn) | ARN of the hybrid node IAM role (from modules/hybrid-node-role). Creates HYBRID\_LINUX access entry. | `string` | `null` | no |
| <a name="input_ip_family"></a> [ip\_family](#input\_ip\_family) | IP family for the cluster (ipv4 or ipv6) | `string` | `"ipv4"` | no |
| <a name="input_managed_node_groups"></a> [managed\_node\_groups](#input\_managed\_node\_groups) | Map of managed node group configurations.<br/>Example:<br/>{<br/>  general = {<br/>    instance\_types = ["m5.large"]<br/>    min\_size       = 2<br/>    max\_size       = 10<br/>    desired\_size   = 3<br/>    disk\_size      = 50<br/>    capacity\_type  = "ON\_DEMAND"<br/>  }<br/>} | <pre>map(object({<br/>    node_role_arn  = string<br/>    instance_types = optional(list(string), ["m5.large"])<br/>    capacity_type  = optional(string, "ON_DEMAND")<br/>    disk_size      = optional(number, 50)<br/>    min_size       = optional(number, 1)<br/>    max_size       = optional(number, 5)<br/>    desired_size   = optional(number, 2)<br/>    subnet_ids     = optional(list(string))<br/>    labels         = optional(map(string), {})<br/>    taints = optional(list(object({<br/>      key    = string<br/>      value  = optional(string)<br/>      effect = string<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_outpost_arns"></a> [outpost\_arns](#input\_outpost\_arns) | ARNs of AWS Outposts for hybrid cluster deployment | `list(string)` | `[]` | no |
| <a name="input_outpost_control_plane_instance_type"></a> [outpost\_control\_plane\_instance\_type](#input\_outpost\_control\_plane\_instance\_type) | Instance type for EKS control plane on Outposts (e.g., m5.large) | `string` | `"m5.large"` | no |
| <a name="input_remote_network_config"></a> [remote\_network\_config](#input\_remote\_network\_config) | Remote network configuration for hybrid clusters | <pre>object({<br/>    remote_node_cidrs = optional(list(string), [])<br/>    remote_pod_cidrs  = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Additional security group IDs for the cluster | `list(string)` | `[]` | no |
| <a name="input_service_ipv4_cidr"></a> [service\_ipv4\_cidr](#input\_service\_ipv4\_cidr) | CIDR block for Kubernetes service IPs | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the EKS cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data for the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint URL for the EKS cluster API |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the EKS cluster |
| <a name="output_cluster_log_group_arn"></a> [cluster\_log\_group\_arn](#output\_cluster\_log\_group\_arn) | ARN of the CloudWatch log group for EKS control plane logs |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the EKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | OIDC issuer URL for the cluster |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version of the EKS cluster |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Cluster security group created by EKS |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | Kubernetes version of the cluster |
| <a name="output_hybrid_node_access_entry_arn"></a> [hybrid\_node\_access\_entry\_arn](#output\_hybrid\_node\_access\_entry\_arn) | ARN of the hybrid node access entry |
| <a name="output_node_group_arns"></a> [node\_group\_arns](#output\_node\_group\_arns) | Map of managed node group ARNs |
| <a name="output_node_group_statuses"></a> [node\_group\_statuses](#output\_node\_group\_statuses) | Map of managed node group statuses |
<!-- END_TF_DOCS -->