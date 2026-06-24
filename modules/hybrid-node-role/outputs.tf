output "role_arn" {
  description = "ARN of the hybrid node IAM role"
  value       = aws_iam_role.hybrid_node.arn
}

output "role_name" {
  description = "Name of the hybrid node IAM role"
  value       = aws_iam_role.hybrid_node.name
}

output "ssm_activation_id" {
  description = "SSM activation ID for hybrid node registration"
  value       = try(aws_ssm_activation.hybrid_node[0].id, null)
}

output "ssm_activation_code" {
  description = "SSM activation code (sensitive - use to register nodes)"
  value       = try(aws_ssm_activation.hybrid_node[0].activation_code, null)
  sensitive   = true
}
