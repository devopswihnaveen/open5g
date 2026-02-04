output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.open5gs.repository_url
}

output "kms_key_id_eks" {
  description = "KMS key ID for EKS secrets encryption"
  value       = aws_kms_key.eks.id
}

output "kms_key_id_ebs" {
  description = "KMS key ID for EBS encryption"
  value       = aws_kms_key.ebs.id
}
