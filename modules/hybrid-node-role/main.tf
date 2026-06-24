################################################################################
# Hybrid Node IAM Role
#
# This role is assumed by on-premises/remote nodes to join the EKS cluster.
# Nodes authenticate via SSM hybrid activations or IAM Roles Anywhere.
################################################################################

resource "aws_iam_role" "hybrid_node" {
  name = "${var.cluster_name}-hybrid-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-hybrid-node"
  })
}

resource "aws_iam_role_policy_attachment" "hybrid_node_eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.hybrid_node.name
}

resource "aws_iam_role_policy_attachment" "hybrid_node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.hybrid_node.name
}

resource "aws_iam_role_policy_attachment" "hybrid_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.hybrid_node.name
}

resource "aws_iam_role_policy_attachment" "hybrid_node_additional" {
  for_each = var.additional_policy_arns

  policy_arn = each.value
  role       = aws_iam_role.hybrid_node.name
}

################################################################################
# SSM Hybrid Activation (for on-prem nodes to register)
################################################################################

resource "aws_ssm_activation" "hybrid_node" {
  count = var.create_ssm_activation ? 1 : 0

  name               = "${var.cluster_name}-hybrid-node"
  iam_role           = aws_iam_role.hybrid_node.id
  registration_limit = var.ssm_registration_limit
  expiration_date    = var.ssm_activation_expiry

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-hybrid-node-activation"
  })
}
