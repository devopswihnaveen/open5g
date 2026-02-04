module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    general = {
      name            = "${var.project_name}-${var.environment}-general"
      instance_types  = var.node_group_instance_types
      capacity_type   = "ON_DEMAND"
      
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      labels = {
        role = "general"
      }

      tags = {
        Name = "${var.project_name}-${var.environment}-general-node"
      }

      # Enable IMDS v2
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      # Disk configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            kms_key_id            = aws_kms_key.ebs.arn
            delete_on_termination = true
          }
        }
      }
    }

    workload = {
      name           = "${var.project_name}-${var.environment}-workload"
      instance_types = ["c5.2xlarge", "c5.4xlarge"]
      capacity_type  = "SPOT"
      
      min_size     = 1
      max_size     = 20
      desired_size = 3

      labels = {
        role     = "workload"
        workload = "open5gs"
      }

      taints = {
        dedicated = {
          key    = "workload"
          value  = "open5gs"
          effect = "NO_SCHEDULE"
        }
      }

      tags = {
        Name = "${var.project_name}-${var.environment}-workload-node"
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            kms_key_id            = aws_kms_key.ebs.arn
            delete_on_termination = true
          }
        }
      }
    }
  }

  # Security groups
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # SCTP for N2 interface (AMF)
    ingress_sctp_38412 = {
      description = "SCTP for N2 interface"
      protocol    = "sctp"
      from_port   = 38412
      to_port     = 38412
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # GTP-U for user plane
    ingress_udp_2152 = {
      description = "GTP-U for user plane"
      protocol    = "udp"
      from_port   = 2152
      to_port     = 2152
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks"
    }
  )
}

# KMS key for EKS secrets encryption
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key for ${var.project_name}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-kms"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# KMS key for EBS volumes
resource "aws_kms_key" "ebs" {
  description             = "EBS Encryption Key for ${var.project_name}-${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-ebs-kms"
    }
  )
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# OIDC provider for IRSA
data "tls_certificate" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-oidc"
    }
  )
}
