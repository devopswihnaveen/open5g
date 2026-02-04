# Open5GS DevOps Deployment Guide

Complete production-ready deployment setup for Open5GS 5G Core Network using modern DevOps practices.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Backup & Restore](#backup--restore)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🎯 Overview

This repository contains a complete DevOps setup for deploying Open5GS, including:

- **Docker**: Multi-stage Dockerfile for optimized container images
- **Kubernetes**: Production-ready manifests with HPA, resource limits, and network policies
- **Terraform**: Infrastructure as Code for AWS EKS, VPC, and related resources
- **Helm Charts**: Parameterized deployments with environment-specific values
- **CI/CD**: GitHub Actions and GitLab CI pipelines
- **Monitoring**: Prometheus and Grafana integration
- **Backup**: Automated backup and restore scripts

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Cloud                            │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                  │ │
│  │  ┌────────────────┐         ┌────────────────┐       │ │
│  │  │ Public Subnets │         │Private Subnets │       │ │
│  │  │   (NAT GW)     │         │  (EKS Nodes)   │       │ │
│  │  └────────────────┘         └────────────────┘       │ │
│  │                                                        │ │
│  │  ┌──────────────────────────────────────────────┐    │ │
│  │  │         EKS Cluster (Kubernetes)             │    │ │
│  │  │  ┌────────────────────────────────────────┐  │    │ │
│  │  │  │       Open5GS Namespace                │  │    │ │
│  │  │  │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │  │    │ │
│  │  │  │  │ NRF  │ │ AMF  │ │ SMF  │ │ UPF  │ │  │    │ │
│  │  │  │  └──────┘ └──────┘ └──────┘ └──────┘ │  │    │ │
│  │  │  │  ┌──────┐ ┌──────┐ ┌──────┐          │  │    │ │
│  │  │  │  │ AUSF │ │ UDM  │ │ UDR  │ ...      │  │    │ │
│  │  │  │  └──────┘ └──────┘ └──────┘          │  │    │ │
│  │  │  │  ┌──────────────┐                     │  │    │ │
│  │  │  │  │   MongoDB    │                     │  │    │ │
│  │  │  │  └──────────────┘                     │  │    │ │
│  │  │  └────────────────────────────────────────┘  │    │ │
│  │  │                                              │    │ │
│  │  │  ┌────────────────────────────────────────┐  │    │ │
│  │  │  │      Monitoring Namespace              │  │    │ │
│  │  │  │  ┌────────────┐  ┌────────────┐       │  │    │ │
│  │  │  │  │Prometheus  │  │  Grafana   │       │  │    │ │
│  │  │  │  └────────────┘  └────────────┘       │  │    │ │
│  │  │  └────────────────────────────────────────┘  │    │ │
│  │  └──────────────────────────────────────────────┘    │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │   ECR    │  │    S3    │  │  KMS     │                 │
│  └──────────┘  └──────────┘  └──────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

## ✅ Prerequisites

### Required Tools

- **Terraform** >= 1.5.0
- **kubectl** >= 1.28
- **Helm** >= 3.13
- **Docker** >= 24.0
- **AWS CLI** >= 2.x
- **Git**

### AWS Requirements

- AWS Account with appropriate permissions
- IAM user with programmatic access
- S3 bucket for Terraform state
- DynamoDB table for state locking

### Install Tools (Ubuntu/Debian)

```bash
# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <repository-url>
cd open5gs-devops
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 3. Initialize Terraform Backend

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://open5gs-terraform-state --region us-east-1

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 4. Deploy Using Automation Script

```bash
cd scripts
./deploy.sh full
```

This will:
1. Check all dependencies
2. Deploy infrastructure with Terraform
3. Build and push Docker images
4. Deploy Open5GS with Helm
5. Verify the deployment
6. Setup monitoring

## 📝 Detailed Setup

### Step 1: Infrastructure Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var="environment=prod" -out=tfplan

# Apply the configuration
terraform apply tfplan
```

### Step 2: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name open5gs-prod

# Verify connection
kubectl get nodes
```

### Step 3: Build Docker Images

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build image
cd docker
docker build -t open5gs:latest .

# Tag and push
docker tag open5gs:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/open5gs/prod:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/open5gs/prod:latest
```

### Step 4: Deploy with Helm

```bash
cd helm

# Install or upgrade
helm upgrade --install open5gs ./open5gs \
  --namespace open5gs \
  --create-namespace \
  --values ./open5gs/values-production.yaml \
  --wait
```

### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n open5gs

# Check services
kubectl get svc -n open5gs

# Check logs
kubectl logs -f deployment/open5gs-nrf -n open5gs
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# Environment
ENVIRONMENT=prod

# EKS Configuration
EKS_CLUSTER_NAME=open5gs-prod
EKS_NODE_INSTANCE_TYPE=t3.xlarge

# Network Configuration
PLMN_MCC=001
PLMN_MNC=01
TAC=1

# MongoDB
MONGODB_URI=mongodb://mongodb:27017/open5gs

# Backup
BACKUP_RETENTION_DAYS=7
S3_BACKUP_BUCKET=open5gs-prod-backups
```

### Customize Helm Values

Edit `helm/open5gs/values-production.yaml`:

```yaml
amf:
  replicaCount: 3
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi
  
  config:
    guami:
      plmn_id:
        mcc: "001"
        mnc: "01"
```

## 📊 Monitoring

### Access Grafana Dashboard

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Access at http://localhost:3000
# Default credentials: admin / admin123
```

### Pre-configured Dashboards

1. **Open5GS Overview**: All network functions status
2. **AMF Metrics**: AMF-specific metrics and connections
3. **SMF Metrics**: Session management metrics
4. **UPF Metrics**: User plane throughput and packet stats

### Custom Metrics

Open5GS components expose metrics on port 9090:

```bash
# View AMF metrics
kubectl port-forward -n open5gs svc/open5gs-amf 9090:9090
curl http://localhost:9090/metrics
```

## 💾 Backup & Restore

### Automated Backup

```bash
# Run backup
./scripts/backup.sh backup

# Backup uploads to S3 automatically
```

### Manual Backup

```bash
# Backup MongoDB only
kubectl exec -n open5gs mongodb-0 -- mongodump --archive=/tmp/backup.archive --gzip

# Copy from pod
kubectl cp open5gs/mongodb-0:/tmp/backup.archive ./mongodb-backup.archive
```

### Restore from Backup

```bash
# Download from S3
aws s3 cp s3://open5gs-prod-backups/backups/open5gs-backup-20240101-120000.tar.gz .

# Restore
./scripts/backup.sh restore open5gs-backup-20240101-120000.tar.gz
```

### Schedule Automated Backups

Create a Kubernetes CronJob:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: open5gs-backup
  namespace: open5gs
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tools:latest
            command: ["/scripts/backup.sh"]
            env:
            - name: S3_BUCKET
              value: "open5gs-prod-backups"
          restartPolicy: OnFailure
```

## 🔧 Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n open5gs

# Check logs
kubectl logs <pod-name> -n open5gs

# Check events
kubectl get events -n open5gs --sort-by='.lastTimestamp'
```

#### Network Connectivity Issues

```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup open5gs-nrf.open5gs.svc.cluster.local

# Test service connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
curl http://open5gs-nrf:7777
```

#### MongoDB Connection Issues

```bash
# Check MongoDB status
kubectl exec -it mongodb-0 -n open5gs -- mongosh

# Check MongoDB logs
kubectl logs mongodb-0 -n open5gs
```

#### HPA Not Scaling

```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n open5gs

# Check HPA status
kubectl get hpa -n open5gs
kubectl describe hpa open5gs-amf-hpa -n open5gs
```

## 🎯 Best Practices

### Security

1. **Enable Pod Security Policies**
   - Use restricted PSPs for all pods
   - Run containers as non-root where possible

2. **Network Policies**
   - Implement network segmentation
   - Restrict inter-pod communication

3. **Secrets Management**
   - Use AWS Secrets Manager or Kubernetes secrets
   - Encrypt secrets at rest
   - Rotate credentials regularly

4. **RBAC**
   - Use least privilege principle
   - Create service-specific service accounts

### High Availability

1. **Multi-AZ Deployment**
   - Deploy nodes across multiple availability zones
   - Use pod anti-affinity rules

2. **Autoscaling**
   - Configure HPA for stateless components
   - Use cluster autoscaler for node scaling

3. **Health Checks**
   - Implement proper liveness and readiness probes
   - Set appropriate timeouts

### Performance

1. **Resource Allocation**
   - Set appropriate CPU and memory limits
   - Use guaranteed QoS for critical components

2. **Network Optimization**
   - Use host networking for UPF when needed
   - Configure proper MTU settings

3. **Storage**
   - Use provisioned IOPS for MongoDB
   - Implement proper backup strategy

### Monitoring

1. **Metrics**
   - Enable Prometheus metrics on all components
   - Set up alerting rules

2. **Logging**
   - Centralize logs with ELK or CloudWatch
   - Set appropriate log levels

3. **Tracing**
   - Implement distributed tracing with Jaeger
   - Track request flows across components

## 📚 Additional Resources

- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)

## 🤝 Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Email: devops@example.com
- Slack: #open5gs-devops
