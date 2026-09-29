# ============================================================
# IAM Roles
# ============================================================

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# ============================================================
# Launch Template (Enables 110 pods per node via prefix delegation)
# ============================================================
# NOTE: instance_type and ami are specified HERE, not in the node group.

resource "aws_launch_template" "eks_nodes" {
  name_prefix = "${var.cluster_name}-node-lt-"

  # Instance type lives in the launch template
  instance_type = var.node_instance_type

  # AMI type is defined via the image_id in user_data bootstrap
  # (EKS auto-selects the right AMI based on ami_type in the node group)

  user_data = base64encode(<<-EOF
    MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

    --==MYBOUNDARY==
    Content-Type: text/x-shellscript; charset="us-ascii"

    #!/bin/bash
    /etc/eks/bootstrap.sh ${var.cluster_name} \
      --use-max-pods false \
      --kubelet-extra-args '--max-pods=110'

    --==MYBOUNDARY==--
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.cluster_name}-node-volume"
    }
  }

  tags = {
    Name = "${var.cluster_name}-node-lt"
  }
}

# ============================================================
# EKS Cluster
# ============================================================

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    # Add this explicitly so it doesn't drift
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  # ⭐ ADD THIS LIFECYCLE BLOCK ⭐
  lifecycle {
    ignore_changes = [
      # AWS adds these automatically — don't let Terraform try to remove them
      compute_config,
      control_plane_scaling_config,
      kube_api_server_config,
      kube_controller_manager_config,
      kube_scheduler_config,
      kubernetes_network_config,
      storage_config,
      upgrade_policy,
      vpc_config[0].public_access_cidrs,
      vpc_config[0].control_plane_egress_mode,
      vpc_config[0].security_group_ids,
      access_config[0].bootstrap_cluster_creator_admin_permissions,
    ]
  }

  tags = {
    Name = var.cluster_name
  }
}

# ============================================================
# EKS Node Group (Uses Launch Template)
# ============================================================

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  # ami_type stays in the node group (EKS needs to know which AMI to use).
  # instance_types is REMOVED because it's now in the launch template.
  ami_type      = "AL2023_ARM_64_STANDARD"
  capacity_type = "ON_DEMAND"

  # Reference the launch template that sets max-pods=110
  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr
  ]

  tags = {
    Name = "${var.cluster_name}-nodes"
  }
}

# ============================================================
# OIDC Provider (for IRSA)
# ============================================================

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.oidc.certificates[0].sha1_fingerprint
  ]

  tags = {
    Name = "${var.cluster_name}-oidc"
  }

  # ⭐ ADD THIS ⭐
  lifecycle {
    ignore_changes = [
      thumbprint_list,
    ]
  }
}