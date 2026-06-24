################################################################################
# Cluster
################################################################################

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_security_group_id" {
  description = "Cluster security group created by EKS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

################################################################################
# Node Groups
################################################################################

output "node_group_arns" {
  description = "Map of managed node group ARNs"
  value       = { for k, v in aws_eks_node_group.this : k => v.arn }
}

output "node_group_statuses" {
  description = "Map of managed node group statuses"
  value       = { for k, v in aws_eks_node_group.this : k => v.status }
}

################################################################################
# CloudWatch
################################################################################

output "cluster_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS control plane logs"
  value       = aws_cloudwatch_log_group.this.arn
}
