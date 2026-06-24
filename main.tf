################################################################################
# EKS Cluster
################################################################################

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.security_group_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
    ip_family         = var.ip_family
  }

  dynamic "encryption_config" {
    for_each = var.cluster_encryption_kms_key_arn != null ? [1] : []
    content {
      resources = ["secrets"]
      provider {
        key_arn = var.cluster_encryption_kms_key_arn
      }
    }
  }

  dynamic "outpost_config" {
    for_each = var.cluster_type == "hybrid" && length(var.outpost_arns) > 0 ? [1] : []
    content {
      outpost_arns                = var.outpost_arns
      control_plane_instance_type = var.outpost_control_plane_instance_type
    }
  }

  dynamic "remote_network_config" {
    for_each = var.cluster_type == "hybrid" && var.remote_network_config != null ? [var.remote_network_config] : []
    content {
      dynamic "remote_node_networks" {
        for_each = length(remote_network_config.value.remote_node_cidrs) > 0 ? [1] : []
        content {
          cidrs = remote_network_config.value.remote_node_cidrs
        }
      }
      dynamic "remote_pod_networks" {
        for_each = length(remote_network_config.value.remote_pod_cidrs) > 0 ? [1] : []
        content {
          cidrs = remote_network_config.value.remote_pod_cidrs
        }
      }
    }
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  access_config {
    authentication_mode = var.authentication_mode
  }

  tags = merge(var.tags, {
    Name        = var.name
    ClusterType = var.cluster_type
  })

  depends_on = [aws_cloudwatch_log_group.this]
}

################################################################################
# CloudWatch Log Group for Control Plane
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = var.tags
}

################################################################################
# EKS Access Entries
################################################################################

resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = try(each.value.type, "STANDARD")

  tags = var.tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = { for k, v in var.access_entries : k => v if try(v.policy_arn, "") != "" }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope.type
    namespaces = try(each.value.access_scope.namespaces, null)
  }

  depends_on = [aws_eks_access_entry.this]
}

################################################################################
# Hybrid Node Access Entry
################################################################################

resource "aws_eks_access_entry" "hybrid_nodes" {
  count = var.cluster_type == "hybrid" && var.hybrid_node_role_arn != null ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.hybrid_node_role_arn
  type          = "HYBRID_LINUX"

  tags = merge(var.tags, {
    Name = "${var.name}-hybrid-node-access"
  })
}

################################################################################
# Managed Node Groups
################################################################################

resource "aws_eks_node_group" "this" {
  for_each = var.managed_node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-${each.key}"
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = coalesce(try(each.value.subnet_ids, null), var.subnet_ids)
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  disk_size       = each.value.disk_size

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}), {
    Name = "${var.name}-${each.key}"
  })

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
