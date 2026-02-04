# Open5GS DevOps - Project Structure

```
open5gs-devops/
│
├── README.md                      # Main documentation
├── QUICKSTART.md                  # Quick start guide
├── Makefile                       # Common operations
├── .gitignore                     # Git ignore patterns
│
├── docker/                        # Docker configuration
│   ├── Dockerfile                 # Multi-stage Open5GS image
│   ├── docker-compose.yml         # Local development setup
│   └── .dockerignore              # Docker ignore patterns
│
├── kubernetes/                    # Kubernetes manifests
│   ├── 00-namespace.yaml          # Namespace and resource quotas
│   ├── 01-configmaps.yaml         # Configuration for all NFs
│   ├── 02-mongodb.yaml            # StatefulSet for MongoDB
│   ├── 03-deployments.yaml        # All network function deployments
│   └── 04-hpa.yaml                # Horizontal Pod Autoscalers
│
├── terraform/                     # Infrastructure as Code
│   ├── main.tf                    # Provider and backend config
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── vpc.tf                     # VPC and networking
│   ├── eks.tf                     # EKS cluster configuration
│   └── monitoring.tf              # ECR, S3, CloudWatch
│
├── helm/                          # Helm charts
│   └── open5gs/
│       ├── Chart.yaml             # Chart metadata
│       ├── values.yaml            # Default values
│       ├── values-staging.yaml    # Staging environment values
│       ├── values-production.yaml # Production environment values
│       └── templates/             # Kubernetes templates
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── hpa.yaml
│           └── ingress.yaml
│
├── ci-cd/                         # CI/CD pipelines
│   ├── github-actions.yml         # GitHub Actions workflow
│   ├── .gitlab-ci.yml             # GitLab CI configuration
│   └── jenkins/                   # Jenkins pipeline
│       └── Jenkinsfile
│
├── scripts/                       # Automation scripts
│   ├── deploy.sh                  # Main deployment script
│   ├── backup.sh                  # Backup and restore
│   ├── health-check.sh            # Health monitoring
│   └── cleanup.sh                 # Resource cleanup
│
├── docs/                          # Additional documentation
│   ├── architecture.md            # Architecture diagrams
│   ├── network-config.md          # Network configuration
│   ├── security-hardening.md      # Security best practices
│   ├── troubleshooting.md         # Common issues and fixes
│   └── performance-tuning.md      # Performance optimization
│
└── tests/                         # Testing
    ├── integration/               # Integration tests
    ├── smoke/                     # Smoke tests
    └── load/                      # Load testing scripts
```

## File Descriptions

### Root Level Files

- **README.md**: Comprehensive documentation covering all aspects
- **QUICKSTART.md**: Get started in 30 minutes
- **Makefile**: Convenient commands for common operations
- **.gitignore**: Excludes sensitive and generated files

### Docker Directory

- **Dockerfile**: Multi-stage build for optimized images
  - Builder stage: Compiles Open5GS from source
  - Runtime stage: Minimal production image
  - Includes all dependencies and security hardening

- **docker-compose.yml**: Complete local development environment
  - All Open5GS network functions
  - MongoDB database
  - WebUI
  - Networking configured for inter-service communication

### Kubernetes Directory

Organized by deployment order (prefixed with numbers):

- **00-namespace.yaml**: 
  - Namespace creation
  - Resource quotas
  - Limit ranges

- **01-configmaps.yaml**: 
  - Configuration for all network functions
  - Organized by NF type
  - Easy to customize

- **02-mongodb.yaml**: 
  - StatefulSet for persistent data
  - PVC for data persistence
  - Health checks configured

- **03-deployments.yaml**: 
  - All network function deployments
  - Services for each NF
  - Resource limits and requests
  - Liveness and readiness probes

- **04-hpa.yaml**: 
  - Horizontal Pod Autoscalers
  - CPU and memory-based scaling
  - Configured for AMF and SMF

### Terraform Directory

Infrastructure as Code for AWS:

- **main.tf**: Core Terraform configuration
  - Provider setup
  - Backend configuration (S3 + DynamoDB)
  - Required versions

- **variables.tf**: All configurable parameters
  - AWS region and environment
  - Network configuration
  - EKS settings
  - Feature flags

- **vpc.tf**: Networking infrastructure
  - VPC with public and private subnets
  - NAT gateways
  - Flow logs for security
  - Proper tagging for EKS

- **eks.tf**: EKS cluster
  - Managed node groups
  - Cluster addons (EBS CSI, VPC CNI)
  - IRSA enabled
  - Encryption with KMS
  - Security groups

- **monitoring.tf**: Supporting resources
  - ECR repository with lifecycle policies
  - S3 bucket for backups
  - CloudWatch log groups
  - KMS keys for encryption

- **outputs.tf**: Useful output values
  - VPC and subnet IDs
  - EKS cluster information
  - Commands for configuration

### Helm Directory

Helm chart for application deployment:

- **Chart.yaml**: Chart metadata and dependencies
- **values.yaml**: Default configuration values
- **values-staging.yaml**: Staging-specific overrides
- **values-production.yaml**: Production-specific overrides

### CI/CD Directory

Automated pipelines:

- **github-actions.yml**: GitHub Actions workflow
  - Multi-stage pipeline
  - Code quality checks
  - Security scanning
  - Build and push
  - Deploy to staging/production
  - Rollback capability

- **.gitlab-ci.yml**: GitLab CI configuration
  - Similar stages to GitHub Actions
  - Supports manual approvals
  - Environment-specific deployments

### Scripts Directory

Automation tools:

- **deploy.sh**: 
  - Interactive menu-driven deployment
  - Full automation or step-by-step
  - Dependency checking
  - Error handling

- **backup.sh**: 
  - MongoDB backup
  - ConfigMap/Secret backup
  - Upload to S3
  - Automated cleanup
  - Restore functionality

## Usage Patterns

### For Development

```bash
# Use Docker Compose for local testing
cd docker
docker-compose up -d
```

### For Staging

```bash
# Deploy infrastructure
cd terraform
terraform apply -var="environment=staging"

# Deploy application
cd helm
helm install open5gs ./open5gs -f values-staging.yaml
```

### For Production

```bash
# Use automation script
./scripts/deploy.sh full

# Or use Makefile
make deploy
```

### For CI/CD

- Push to `develop` branch → Deploy to staging
- Push to `main` branch → Deploy to production (with approval)
- Tag release → Deploy specific version

## Customization Guide

### Network Configuration

Edit `helm/open5gs/values.yaml`:
```yaml
amf:
  config:
    guami:
      plmn_id:
        mcc: "YOUR_MCC"
        mnc: "YOUR_MNC"
```

### Resource Allocation

Edit values file or deployment:
```yaml
resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 2000m
    memory: 2Gi
```

### Scaling

```bash
# Horizontal scaling
kubectl scale deployment open5gs-amf --replicas=5

# Autoscaling
kubectl autoscale deployment open5gs-amf --min=2 --max=10 --cpu-percent=70
```

## Best Practices

1. **Always use version control** for configuration files
2. **Test changes in staging** before production
3. **Use separate AWS accounts** for different environments
4. **Enable monitoring and alerting** from day one
5. **Schedule regular backups** and test restore procedures
6. **Keep secrets in AWS Secrets Manager** or Kubernetes secrets
7. **Use least privilege** IAM roles and RBAC policies
8. **Tag all resources** for cost tracking and management

## Support

For questions or issues:
- Check troubleshooting guide in README.md
- Review logs: `make k8s-logs`
- Open an issue on GitHub
- Contact: devops@example.com
