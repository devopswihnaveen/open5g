variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "open5gs"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_instance_types" {
  description = "EC2 instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.xlarge", "t3.2xlarge"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 10
}

variable "enable_cluster_autoscaler" {
  description = "Enable Kubernetes cluster autoscaler"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable Kubernetes metrics server"
  type        = bool
  default     = true
}

variable "enable_prometheus" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "enable_grafana" {
  description = "Enable Grafana dashboards"
  type        = bool
  default     = true
}

variable "mongodb_storage_size" {
  description = "Storage size for MongoDB in GB"
  type        = number
  default     = 100
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
