# Open5GS DevOps - Production Deployment Guide

<div align="center">

![Open5GS Logo](https://open5gs.org/assets/img/open5gs-logo.png)

**Complete Production-Ready DevOps Setup for Open5GS 5G Core Network**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Docker](https://img.shields.io/badge/Docker-24+-2496ED?logo=docker)](https://www.docker.com/)

[Features](#-key-features) •
[Quick Start](#-quick-start) •
[Architecture](#-architecture) •
[Documentation](#-documentation) •
[Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
  - [1. Infrastructure Setup](#1-infrastructure-setup-terraform)
  - [2. Docker Setup](#2-docker-setup)
  - [3. Kubernetes Deployment](#3-kubernetes-deployment)
  - [4. Helm Deployment](#4-helm-deployment)
- [Configuration](#-configuration)
- [Monitoring & Observability](#-monitoring--observability)
- [Backup & Disaster Recovery](#-backup--disaster-recovery)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)
- [Performance Tuning](#-performance-tuning)
- [Cost Optimization](#-cost-optimization)
- [FAQ](#-frequently-asked-questions)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

---

## 🎯 Overview

This repository provides a **complete, production-ready DevOps setup** for deploying [Open5GS](https://open5gs.org/) - an open-source 5G Core Network implementation. It includes everything you need to deploy, manage, and scale a 5G core network in the cloud using modern DevOps practices.

### What is Open5GS?

Open5GS is a C-language implementation of 5G Core and EPC (Evolved Packet Core) that follows 3GPP specifications. It supports both 4G LTE and 5G NR standards.

### What This Repository Provides

- ✅ **Production-Grade Infrastructure**: AWS EKS cluster with Terraform
- ✅ **Container Orchestration**: Kubernetes manifests and Helm charts
- ✅ **CI/CD Pipelines**: GitHub Actions and GitLab CI
- ✅ **Monitoring Stack**: Prometheus and Grafana integration
- ✅ **Backup Solutions**: Automated backup and restore scripts
- ✅ **Security Hardening**: Network policies, RBAC, encryption
- ✅ **Auto-Scaling**: HPA and cluster autoscaler
- ✅ **Documentation**: Comprehensive guides and examples

---

## 🌟 Key Features

### Infrastructure as Code (IaC)
- **Terraform** for AWS infrastructure (VPC, EKS, networking)
- Multi-AZ deployment for high availability
- Encrypted storage with AWS KMS
- VPC Flow Logs for security monitoring
- Separate node groups for general and workload pods

### Container & Orchestration
- **Multi-stage Docker** builds for optimized images
- **Kubernetes** manifests with best practices
- **Helm charts** for parameterized deployments
- Resource quotas and limits
- Pod disruption budgets
- Network policies for isolation

### Automation
- One-command deployment with Makefile
- Interactive deployment scripts
- Automated backup and restore
- Health checks and smoke tests
- Blue-green deployment support

### Observability
- **Prometheus** for metrics collection
- **Grafana** dashboards for visualization
- Structured logging with ELK stack support
- Custom alerts and notifications
- Distributed tracing ready

### High Availability
- Multi-replica deployments
- Horizontal Pod Autoscaling (HPA)
- Pod anti-affinity rules
- Rolling updates with zero downtime
- Automatic failover

### Security
- RBAC with least privilege
- Network policies for pod isolation
- Secrets encryption at rest
- Container image scanning
- Security contexts and PSPs

---

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud (Multi-AZ)                       │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                        │   │
│  │                                                             │   │
│  │  ┌──────────────────┐         ┌──────────────────┐         │   │
│  │  │  Public Subnets  │         │ Private Subnets  │         │   │
│  │  │                  │         │                  │         │   │
│  │  │  - NAT Gateway   │────────▶│  - EKS Nodes     │         │   │
│  │  │  - Load Balancer │         │  - Database      │         │   │
│  │  │                  │         │  - App Pods      │         │   │
│  │  └──────────────────┘         └──────────────────┘         │   │
│  │                                                             │   │
│  │  ┌────────────────────────────────────────────────────┐    │   │
│  │  │              EKS Cluster                           │    │   │
│  │  │                                                    │    │   │
│  │  │  ┌──────────────────────────────────────────────┐ │    │   │
│  │  │  │         Open5GS Namespace                   │ │    │   │
│  │  │  │                                              │ │    │   │
│  │  │  │  Control Plane Functions:                   │ │    │   │
│  │  │  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │ │    │   │
│  │  │  │  │ NRF │ │ AMF │ │ SMF │ │AUSF │ │ UDM │  │ │    │   │
│  │  │  │  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘  │ │    │   │
│  │  │  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐          │ │    │   │
│  │  │  │  │ UDR │ │ PCF │ │NSSF │ │ BSF │          │ │    │   │
│  │  │  │  └─────┘ └─────┘ └─────┘ └─────┘          │ │    │   │
│  │  │  │                                              │ │    │   │
│  │  │  │  User Plane Functions:                      │ │    │   │
│  │  │  │  ┌─────────┐                                │ │    │   │
│  │  │  │  │   UPF   │ (Data Plane)                   │ │    │   │
│  │  │  │  └─────────┘                                │ │    │   │
│  │  │  │                                              │ │    │   │
│  │  │  │  Data Storage:                               │ │    │   │
│  │  │  │  ┌──────────────┐                           │ │    │   │
│  │  │  │  │   MongoDB    │ (StatefulSet)             │ │    │   │
│  │  │  │  │   (Replica)  │                           │ │    │   │
│  │  │  │  └──────────────┘                           │ │    │   │
│  │  │  │                                              │ │    │   │
│  │  │  │  Management:                                 │ │    │   │
│  │  │  │  ┌──────────────┐                           │ │    │   │
│  │  │  │  │    WebUI     │                           │ │    │   │
│  │  │  │  └──────────────┘                           │ │    │   │
│  │  │  └──────────────────────────────────────────────┘ │    │   │
│  │  │                                                    │    │   │
│  │  │  ┌──────────────────────────────────────────────┐ │    │   │
│  │  │  │        Monitoring Namespace                  │ │    │   │
│  │  │  │  ┌────────────┐  ┌──────────┐               │ │    │   │
│  │  │  │  │ Prometheus │  │ Grafana  │               │ │    │   │
│  │  │  │  └────────────┘  └──────────┘               │ │    │   │
│  │  │  └──────────────────────────────────────────────┘ │    │   │
│  │  └────────────────────────────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  Supporting Services:                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │   ECR    │  │    S3    │  │   KMS    │  │CloudWatch│          │
│  │(Registry)│  │(Backups) │  │(Encrypt) │  │  (Logs)  │          │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

### Network Function Components

| Component | Description | Replicas | Protocol |
|-----------|-------------|----------|----------|
| **NRF** | Network Repository Function | 1 | HTTP/2 (SBI) |
| **AMF** | Access and Mobility Management | 2-10 (HPA) | SCTP (N2), HTTP/2 (SBI) |
| **SMF** | Session Management Function | 2-10 (HPA) | HTTP/2 (SBI), PFCP |
| **UPF** | User Plane Function | 1-3 | GTP-U, PFCP |
| **AUSF** | Authentication Server Function | 1 | HTTP/2 (SBI) |
| **UDM** | Unified Data Management | 1 | HTTP/2 (SBI) |
| **UDR** | Unified Data Repository | 1 | HTTP/2 (SBI) |
| **PCF** | Policy Control Function | 1 | HTTP/2 (SBI) |
| **NSSF** | Network Slice Selection Function | 1 | HTTP/2 (SBI) |
| **BSF** | Binding Support Function | 1 | HTTP/2 (SBI) |
| **WebUI** | Web User Interface | 1 | HTTP |

### Data Flow

```
gNB/eNB ──(N2)──▶ AMF ──(N11)──▶ SMF ──(N4)──▶ UPF ──▶ Internet
   │                │                │              │
   │                │                │              │
   └─(N3)───────────┴────────────────┴──────────────┘
                                          (User Data)
```

---

## ✅ Prerequisites

### Required Tools

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| **Terraform** | ≥ 1.5.0 | Infrastructure provisioning |
| **kubectl** | ≥ 1.28 | Kubernetes management |
| **Helm** | ≥ 3.13 | Package management |
| **Docker** | ≥ 24.0 | Container runtime |
| **AWS CLI** | ≥ 2.0 | AWS operations |
| **Git** | ≥ 2.0 | Version control |
| **Make** | ≥ 4.0 | Build automation (optional) |

### AWS Requirements

- **AWS Account** with appropriate permissions
- **IAM User** with programmatic access
- **AWS Credentials** configured locally
- **S3 Bucket** for Terraform state (will be created)
- **DynamoDB Table** for state locking (will be created)

#### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "iam:*",
        "s3:*",
        "kms:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### System Requirements

- **OS**: Linux, macOS, or WSL2 on Windows
- **RAM**: 8GB minimum (for local development)
- **Disk**: 20GB free space
- **Network**: Stable internet connection

### Installation of Prerequisites

<details>
<summary><b>Ubuntu/Debian</b></summary>

```bash
# Update package list
sudo apt update

# Install basic tools
sudo apt install -y curl wget git make unzip

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
  https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```
</details>

<details>
<summary><b>macOS</b></summary>

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all tools
brew install terraform kubectl helm awscli docker git make

# Start Docker Desktop
open /Applications/Docker.app
```
</details>

<details>
<summary><b>Windows (WSL2)</b></summary>

```bash
# First, install WSL2 and Ubuntu from Microsoft Store

# Then follow Ubuntu/Debian instructions above
# For Docker Desktop, download from: https://www.docker.com/products/docker-desktop
```
</details>

---

## 🚀 Quick Start

### Fast Track Deployment (30 Minutes)

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/open5gs-devops.git
cd open5gs-devops

# 2. Configure AWS credentials
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: us-east-1
# Default output format: json

# 3. Create Terraform backend
aws s3 mb s3://open5gs-terraform-state --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1

# 4. Deploy everything (one command!)
make deploy

# 5. Verify deployment
make k8s-status
make smoke-test
```

**That's it!** Your Open5GS deployment is ready. 🎉

### Access Your Deployment

```bash
# Get WebUI URL
kubectl get svc open5gs-webui -n open5gs

# Access Grafana dashboards
make monitoring-forward
# Open: http://localhost:3000 (admin/admin123)
```

---

## 📦 Installation

### 1. Infrastructure Setup (Terraform)

#### Step 1.1: Configure Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "prod"
project_name = "open5gs"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS Configuration
eks_cluster_version = "1.28"
node_group_instance_types = ["t3.xlarge", "t3.2xlarge"]
node_group_desired_size = 3
node_group_min_size = 2
node_group_max_size = 10

# Feature Flags
enable_cluster_autoscaler = true
enable_metrics_server = true
enable_prometheus = true
enable_grafana = true

# Storage
mongodb_storage_size = 100
backup_retention_days = 7

# Tags
tags = {
  Project = "Open5GS"
  Team = "Network Engineering"
  CostCenter = "5G-Core"
}
```

#### Step 1.2: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review plan
terraform plan -out=tfplan

# Apply (create infrastructure)
terraform apply tfplan
```

**Expected Resources Created:**
- 1 VPC with 6 subnets (3 public, 3 private)
- 3 NAT Gateways (one per AZ)
- 1 EKS Cluster
- 2 EKS Node Groups (general + workload)
- 1 ECR Repository
- 1 S3 Bucket (backups)
- 3 KMS Keys (EKS, EBS, S3)
- CloudWatch Log Groups
- VPC Flow Logs
- Security Groups

**Time Required:** ~15-20 minutes

#### Step 1.3: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name open5gs-prod

# Verify connection
kubectl get nodes
kubectl cluster-info
```

---

### 2. Docker Setup

#### Option A: Use Pre-built Images (Recommended)

```bash
# Pull from Docker Hub or build your own
docker pull open5gs/open5gs:latest
```

#### Option B: Build Custom Images

```bash
cd docker

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t open5gs:latest -f Dockerfile .

# Tag for ECR
docker tag open5gs:latest \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com/open5gs/prod:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/open5gs/prod:latest
```

#### Local Development with Docker Compose

```bash
cd docker

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access WebUI
open http://localhost:3000

# Stop services
docker-compose down
```

---

### 3. Kubernetes Deployment

#### Using kubectl (Manual Deployment)

```bash
cd kubernetes

# Apply in order
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-configmaps.yaml
kubectl apply -f 02-mongodb.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongodb -n open5gs --timeout=300s

# Deploy network functions
kubectl apply -f 03-deployments.yaml
kubectl apply -f 04-hpa.yaml

# Verify deployment
kubectl get all -n open5gs
```

#### Customize Configuration

Edit ConfigMaps before applying:

```yaml
# kubernetes/01-configmaps.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: open5gs-amf-config
  namespace: open5gs
data:
  amf.yaml: |
    amf:
      guami:
        - plmn_id:
            mcc: "001"  # Change to your MCC
            mnc: "01"   # Change to your MNC
```

---

### 4. Helm Deployment

#### Using Helm (Recommended for Production)

```bash
cd helm

# Add required Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install Open5GS
helm upgrade --install open5gs ./open5gs \
  --namespace open5gs \
  --create-namespace \
  --values ./open5gs/values-production.yaml \
  --wait \
  --timeout 15m

# Check deployment status
helm status open5gs -n open5gs
helm list -n open5gs
```

#### Customize Helm Values

Edit `helm/open5gs/values-production.yaml`:

```yaml
# Network Configuration
amf:
  config:
    guami:
      plmn_id:
        mcc: "001"  # Your Mobile Country Code
        mnc: "01"   # Your Mobile Network Code
    tai:
      plmn_id:
        mcc: "001"
        mnc: "01"
      tac: 1        # Tracking Area Code

# Resource Allocation
amf:
  replicaCount: 3
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi

# Auto-scaling
amf:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

Apply changes:

```bash
helm upgrade open5gs ./open5gs \
  --namespace open5gs \
  --values ./open5gs/values-production.yaml \
  --wait
```

---

## ⚙️ Configuration

### Network Function Configuration

#### PLMN Configuration (MCC/MNC)

The PLMN (Public Land Mobile Network) identifier uniquely identifies your mobile network.

```yaml
# helm/open5gs/values.yaml
amf:
  config:
    guami:
      plmn_id:
        mcc: "001"  # Mobile Country Code (3 digits)
        mnc: "01"   # Mobile Network Code (2-3 digits)
```

**Common PLMNs:**
- Test Network: MCC=001, MNC=01
- USA AT&T: MCC=310, MNC=410
- India Airtel: MCC=404, MNC=45

#### Data Network Name (DNN)

Configure the DNN (also known as APN in 4G):

```yaml
smf:
  config:
    subnet:
      - addr: 10.45.0.1/16
        dnn: internet  # Default DNN
      - addr: 10.46.0.1/16
        dnn: ims       # IMS DNN
```

#### DNS Configuration

```yaml
smf:
  config:
    dns:
      - 8.8.8.8       # Google DNS
      - 8.8.4.4
      - 1.1.1.1       # Cloudflare DNS
```

### Resource Management

#### CPU and Memory Limits

```yaml
# Per network function
amf:
  resources:
    requests:      # Guaranteed resources
      cpu: 500m
      memory: 1Gi
    limits:        # Maximum allowed
      cpu: 2000m
      memory: 2Gi
```

#### Storage Configuration

```yaml
mongodb:
  persistence:
    enabled: true
    size: 100Gi
    storageClass: gp3  # AWS EBS gp3
```

### High Availability Configuration

#### Pod Replicas

```yaml
# Control plane functions
amf:
  replicaCount: 3
smf:
  replicaCount: 3

# User plane functions (typically 1-2)
upf:
  replicaCount: 1
```

#### Anti-Affinity Rules

Add to deployment templates:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values:
                - open5gs-amf
        topologyKey: kubernetes.io/hostname
```

### Auto-Scaling Configuration

```yaml
amf:
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
```

Test scaling:

```bash
# Generate load
kubectl run -it --rm load-generator --image=busybox -n open5gs -- /bin/sh

# Watch HPA
kubectl get hpa -n open5gs -w
```

---

## 📊 Monitoring & Observability

### Prometheus & Grafana Setup

#### Install Monitoring Stack

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123 \
  --wait
```

#### Access Grafana

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser
open http://localhost:3000
# Login: admin / admin123
```

#### Import Pre-configured Dashboards

1. **Open5GS Overview Dashboard**
   - Dashboard ID: Create custom
   - Metrics: Pod status, resource usage, request rates

2. **Kubernetes Cluster Dashboard**
   - Dashboard ID: 7249
   - Shows: Cluster health, node metrics, pod distribution

3. **Network Function Metrics**
   - AMF: Sessions, registrations, authentications
   - SMF: PDU sessions, QoS flows
   - UPF: Throughput, packet loss, latency

#### Custom Metrics

Open5GS components expose Prometheus metrics on port 9090:

```bash
# View AMF metrics
kubectl port-forward -n open5gs svc/open5gs-amf 9090:9090
curl http://localhost:9090/metrics

# Example metrics:
# - amf_session_active_total
# - amf_registration_success_total
# - amf_authentication_success_total
```

### Logging

#### Centralized Logging with ELK Stack

```bash
# Install Elasticsearch and Kibana
helm repo add elastic https://helm.elastic.co
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --create-namespace

helm upgrade --install kibana elastic/kibana \
  --namespace logging

# Install Filebeat for log collection
helm upgrade --install filebeat elastic/filebeat \
  --namespace logging
```

#### View Logs

```bash
# Stream logs from all pods
kubectl logs -f -l app.kubernetes.io/name=open5gs -n open5gs --all-containers=true

# View specific function logs
kubectl logs -f deployment/open5gs-amf -n open5gs
kubectl logs -f deployment/open5gs-smf -n open5gs

# View logs from specific time
kubectl logs --since=1h deployment/open5gs-amf -n open5gs
```

### Alerting

#### Configure Prometheus Alerts

Create `prometheus-rules.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: open5gs-alerts
  namespace: open5gs
spec:
  groups:
    - name: open5gs
      interval: 30s
      rules:
        - alert: Open5GSPodDown
          expr: kube_pod_status_phase{namespace="open5gs",phase="Running"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Open5GS pod is down"
            description: "Pod {{ $labels.pod }} is not running"
        
        - alert: HighCPUUsage
          expr: rate(container_cpu_usage_seconds_total{namespace="open5gs"}[5m]) > 0.8
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "High CPU usage detected"
```

Apply:

```bash
kubectl apply -f prometheus-rules.yaml
```

#### Slack Notifications

Configure Alertmanager:

```yaml
# alertmanager-config.yaml
global:
  slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'

route:
  receiver: 'slack-notifications'
  group_by: ['alertname', 'cluster', 'service']

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - channel: '#open5gs-alerts'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

---

## 💾 Backup & Disaster Recovery

### Automated Backups

#### Schedule Daily Backups

```bash
# Run backup manually
./scripts/backup.sh backup

# Schedule with cron
crontab -e
# Add: 0 2 * * * /path/to/scripts/backup.sh backup
```

#### Configure Backup CronJob

Create `backup-cronjob.yaml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: open5gs-backup
  namespace: open5gs
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: backup-sa
          containers:
          - name: backup
            image: mongo:6.0
            command:
            - /bin/bash
            - -c
            - |
              mongodump --host=mongodb --archive=/backup/dump-$(date +%Y%m%d).archive --gzip
              aws s3 cp /backup/ s3://open5gs-prod-backups/backups/ --recursive
            env:
            - name: AWS_REGION
              value: us-east-1
            volumeMounts:
            - name: backup-volume
              mountPath: /backup
          volumes:
          - name: backup-volume
            emptyDir: {}
          restartPolicy: OnFailure
```

### Restore from Backup

#### Restore Database

```bash
# Download backup from S3
aws s3 cp s3://open5gs-prod-backups/backups/open5gs-backup-20240101-120000.tar.gz .

# Restore using script
./scripts/backup.sh restore open5gs-backup-20240101-120000.tar.gz
```

#### Manual Restore

```bash
# Copy backup to MongoDB pod
kubectl cp mongodb-backup.archive open5gs/mongodb-0:/tmp/restore.archive

# Restore
kubectl exec -it mongodb-0 -n open5gs -- \
  mongorestore --archive=/tmp/restore.archive --gzip --drop
```

### Disaster Recovery Plan

#### 1. Regular Backups
- **Daily**: Full MongoDB backup
- **Hourly**: ConfigMap and Secret snapshots
- **Weekly**: Full cluster snapshot (EBS volumes)

#### 2. Multi-Region Setup
```hcl
# terraform/variables.tf
variable "regions" {
  default = ["us-east-1", "us-west-2"]
}
```

#### 3. Recovery Time Objective (RTO)
- **Target**: < 1 hour
- **Database**: < 30 minutes
- **Application**: < 30 minutes

#### 4. Recovery Point Objective (RPO)
- **Target**: < 1 hour (hourly backups)
- **Critical**: < 15 minutes (with continuous backup)

---

## 🔄 CI/CD Pipeline

### GitHub Actions

The repository includes a complete GitHub Actions workflow:

**File**: `.github/workflows/ci-cd.yml`

#### Pipeline Stages

1. **Code Quality**
   - Hadolint (Dockerfile linting)
   - Trivy (vulnerability scanning)
   - Terraform validation

2. **Build**
   - Docker image build
   - Multi-platform support
   - Push to ECR

3. **Test**
   - Unit tests
   - Integration tests
   - Security scanning

4. **Deploy Staging**
   - Deploy to staging environment
   - Run smoke tests
   - Automated approval

5. **Deploy Production**
   - Manual approval required
   - Blue-green deployment
   - Health checks
   - Automatic rollback on failure

#### Configure Secrets

Add these secrets in GitHub repository settings:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
SLACK_WEBHOOK (optional)
```

#### Trigger Deployment

```bash
# Push to develop → Deploy to staging
git checkout develop
git push origin develop

# Push to main → Deploy to production (with approval)
git checkout main
git merge develop
git push origin main

# Tag release → Deploy specific version
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### GitLab CI

**File**: `.gitlab-ci.yml`

#### Configure Variables

In GitLab project settings, add:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
CI_REGISTRY (ECR URL)
```

#### Pipeline Execution

```bash
# Merge request → Run validation and tests
# Merge to develop → Deploy to staging
# Merge to main → Manual production deployment
```

### ArgoCD (GitOps)

#### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### Create Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: open5gs
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/open5gs-devops.git
    targetRevision: main
    path: helm/open5gs
    helm:
      valueFiles:
        - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: open5gs
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🔒 Security

### Network Policies

#### Restrict Inter-Pod Communication

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: open5gs-network-policy
  namespace: open5gs
spec:
  podSelector:
    matchLabels:
      app: open5gs
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: open5gs
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: open5gs
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: TCP
          port: 53  # DNS
```

### RBAC Configuration

#### Create Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: open5gs-sa
  namespace: open5gs
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: open5gs-role
  namespace: open5gs
rules:
  - apiGroups: [""]
    resources: ["configmaps", "secrets"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: open5gs-rolebinding
  namespace: open5gs
subjects:
  - kind: ServiceAccount
    name: open5gs-sa
roleRef:
  kind: Role
  name: open5gs-role
  apiGroup: rbac.authorization.k8s.io
```

### Secrets Management

#### Using AWS Secrets Manager

```bash
# Create secret
aws secretsmanager create-secret \
  --name open5gs/prod/mongodb \
  --secret-string '{"username":"admin","password":"secure-password"}'

# Use External Secrets Operator
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```

#### Encrypt Secrets at Rest

Enabled automatically with KMS in Terraform configuration.

### Pod Security

#### Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  capabilities:
    drop:
      - ALL
    add:
      - NET_ADMIN  # Only for UPF
```

### Image Scanning

#### Trivy Scanning

```bash
# Scan image
trivy image open5gs:latest

# Scan filesystem
trivy fs .

# Scan with severity filter
trivy image --severity CRITICAL,HIGH open5gs:latest
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Pods Not Starting

**Symptoms:**
```bash
kubectl get pods -n open5gs
# Shows: CrashLoopBackOff or Error
```

**Diagnosis:**
```bash
# Check pod status
kubectl describe pod <pod-name> -n open5gs

# Check logs
kubectl logs <pod-name> -n open5gs

# Check events
kubectl get events -n open5gs --sort-by='.lastTimestamp'
```

**Common Causes:**
- Insufficient resources
- Configuration errors
- Image pull failures
- Network issues

**Solutions:**
```bash
# Increase resources
kubectl edit deployment open5gs-amf -n open5gs

# Fix configuration
kubectl edit configmap open5gs-amf-config -n open5gs
kubectl rollout restart deployment open5gs-amf -n open5gs

# Check image
kubectl get pods -n open5gs -o jsonpath='{.items[*].spec.containers[*].image}'
```

#### 2. MongoDB Connection Failures

**Symptoms:**
```
Error: Failed to connect to MongoDB
```

**Diagnosis:**
```bash
# Check MongoDB status
kubectl get pods -l app=mongodb -n open5gs
kubectl logs mongodb-0 -n open5gs

# Test connection
kubectl run -it --rm debug --image=mongo:6.0 -n open5gs -- \
  mongosh mongodb://mongodb:27017/open5gs
```

**Solutions:**
```bash
# Restart MongoDB
kubectl rollout restart statefulset mongodb -n open5gs

# Check persistent volume
kubectl get pvc -n open5gs

# Restore from backup if corrupted
./scripts/backup.sh restore <backup-file>
```

#### 3. Network Connectivity Issues

**Symptoms:**
```
NF registration failed
Connection timeout
```

**Diagnosis:**
```bash
# Test DNS
kubectl run -it --rm debug --image=busybox -n open5gs -- \
  nslookup open5gs-nrf.open5gs.svc.cluster.local

# Test service connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot -n open5gs -- \
  curl http://open5gs-nrf:7777

# Check network policies
kubectl get networkpolicies -n open5gs
```

**Solutions:**
```bash
# Verify services
kubectl get svc -n open5gs

# Check endpoints
kubectl get endpoints -n open5gs

# Disable network policy temporarily
kubectl delete networkpolicy --all -n open5gs
```

#### 4. HPA Not Scaling

**Symptoms:**
```
HPA shows <unknown> for current metrics
```

**Diagnosis:**
```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n open5gs

# Check HPA status
kubectl get hpa -n open5gs
kubectl describe hpa open5gs-amf-hpa -n open5gs
```

**Solutions:**
```bash
# Install metrics server if missing
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check resource requests are set
kubectl get deployment open5gs-amf -n open5gs -o yaml | grep -A 5 resources
```

### Debug Commands

```bash
# Interactive debugging pod
kubectl run -it --rm debug --image=nicolaka/netshoot -n open5gs -- /bin/bash

# Inside debug pod:
ping open5gs-nrf
nslookup open5gs-nrf
curl http://open5gs-nrf:7777
tcpdump -i any port 7777

# Check all resources
kubectl get all,cm,secret,pvc,networkpolicy -n open5gs

# Describe all pods
kubectl describe pods -n open5gs

# Get logs from all pods
kubectl logs -l app.kubernetes.io/name=open5gs -n open5gs --all-containers=true

# Port forward for local testing
kubectl port-forward svc/open5gs-nrf 7777:7777 -n open5gs
```

### Performance Issues

#### High CPU Usage

```bash
# Identify high CPU pods
kubectl top pods -n open5gs --sort-by=cpu

# Scale up
kubectl scale deployment open5gs-amf --replicas=5 -n open5gs

# Adjust HPA targets
kubectl edit hpa open5gs-amf-hpa -n open5gs
```

#### High Memory Usage

```bash
# Check memory usage
kubectl top pods -n open5gs --sort-by=memory

# Increase limits
kubectl set resources deployment open5gs-amf \
  --limits=memory=2Gi -n open5gs
```

#### Network Latency

```bash
# Test latency
kubectl run -it --rm perf --image=networkstatic/iperf3 -n open5gs -- \
  iperf3 -c open5gs-upf

# Check MTU settings
kubectl exec -it <upf-pod> -n open5gs -- ip link show
```

---

## ⚡ Performance Tuning

### Resource Optimization

#### Right-Sizing Pods

```yaml
# Start with these baselines
nrf:
  resources:
    requests: { cpu: 100m, memory: 128Mi }
    limits: { cpu: 500m, memory: 256Mi }

amf:
  resources:
    requests: { cpu: 300m, memory: 512Mi }
    limits: { cpu: 1000m, memory: 1Gi }

smf:
  resources:
    requests: { cpu: 300m, memory: 512Mi }
    limits: { cpu: 1000m, memory: 1Gi }

upf:
  resources:
    requests: { cpu: 500m, memory: 1Gi }
    limits: { cpu: 2000m, memory: 2Gi }
```

#### Adjust Based on Load

```bash
# Monitor actual usage
kubectl top pods -n open5gs --containers

# Use Vertical Pod Autoscaler (VPA) for recommendations
kubectl describe vpa <vpa-name> -n open5gs
```

### Network Performance

#### Enable Host Networking for UPF

```yaml
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
```

#### Optimize MTU

```bash
# Check current MTU
kubectl exec -it <upf-pod> -n open5gs -- ip link show

# Set jumbo frames if network supports
# MTU 9000 for high-throughput scenarios
```

### Database Optimization

#### MongoDB Tuning

```yaml
mongodb:
  resources:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 4Gi
  
  # Use provisioned IOPS
  persistence:
    storageClass: io2  # High-performance EBS
    size: 100Gi
```

#### Connection Pooling

```yaml
udr:
  config:
    db_uri: mongodb://mongodb:27017/open5gs?maxPoolSize=100
```

### Cluster Autoscaler

#### Enable Cluster Autoscaling

Already configured in Terraform. Verify:

```bash
kubectl get deployment cluster-autoscaler -n kube-system

# Check logs
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

#### Configure Node Group Scaling

```hcl
# terraform/eks.tf
min_size = 2
max_size = 20
desired_size = 3
```

---

## 💰 Cost Optimization

### Current Cost Breakdown

**Monthly Estimates (us-east-1):**

|     Resource    | Quantity | Unit Cost | Total |
|-----------------|----------|-----------|-------|
| EKS Cluster     |     1    | $73/month | $73 |
| EC2 t3.xlarge   |     3    | $122/month| $366 |
| EBS gp3 (100GB) |     4    | $8/month  | $32 |
| NAT Gateway     |     3    | $32/month | $96 |
| Load Balancer   |     1    | $20/month | $20 |
| Data Transfer   | Variable |    -      | $50 |
| **Total**       |          |           | **~$637/month** |

### Cost Reduction Strategies

#### 1. Use Spot Instances

```hcl
# terraform/eks.tf
capacity_type = "SPOT"
```

**Savings:** 50-70% on compute costs (~$150-250/month)

#### 2. Right-Size Instances

```hcl
# Use smaller instances if load permits
instance_types = ["t3.large", "t3.xlarge"]
```

**Savings:** ~$100/month

#### 3. Single NAT Gateway (Non-Production)

```hcl
# terraform/vpc.tf
single_nat_gateway = true
```

**Savings:** ~$64/month

#### 4. Use Reserved Instances

Purchase 1-year reserved instances for predictable workloads.

**Savings:** 30-40% on compute (~$100/month)

#### 5. Enable Cluster Autoscaler

Automatically scale down during low usage.

**Savings:** Variable, ~20-30% average

#### 6. Optimize Storage

```hcl
# Use gp3 instead of gp2
volume_type = "gp3"
```

**Savings:** ~20% on storage costs

### Monitoring Costs

```bash
# AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-02-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Project

# Tag all resources
tags = {
  Project = "Open5GS"
  Environment = "Production"
}
```

### Cost Alerts

Create CloudWatch alarms:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name high-costs \
  --alarm-description "Alert when monthly costs exceed $700" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 700 \
  --comparison-operator GreaterThanThreshold
```

---

## ❓ Frequently Asked Questions

<details>
<summary><b>Can I deploy this on other cloud providers (GCP, Azure)?</b></summary>

Yes! The Kubernetes and Helm configurations are cloud-agnostic. You'll need to:
1. Replace Terraform AWS modules with GCP/Azure equivalents
2. Adjust storage classes
3. Update load balancer annotations

We're working on multi-cloud Terraform modules.
</details>

<details>
<summary><b>How do I upgrade to a new Open5GS version?</b></summary>

```bash
# Update Docker image tag
docker build -t open5gs:v2.7.1 .

# Update Helm values
helm upgrade open5gs ./helm/open5gs \
  --set global.imageTag=v2.7.1

# Or use rolling update
kubectl set image deployment/open5gs-amf \
  amf=open5gs:v2.7.1 -n open5gs
```
</details>

<details>
<summary><b>Can I run this on bare metal or on-premises?</b></summary>

Yes! You can:
1. Skip the Terraform AWS setup
2. Deploy Kubernetes using kubeadm, k3s, or existing cluster
3. Use kubectl or Helm to deploy
4. Replace AWS-specific components (EBS → local PV, ELB → MetalLB)
</details>

<details>
<summary><b>How do I connect real UE devices?</b></summary>

You'll need:
1. A gNB/eNB connected to AMF (SCTP on port 38412)
2. Configure PLMN to match your SIM cards
3. Add subscribers in WebUI
4. Route UPF traffic properly

See detailed guide in `docs/ue-connectivity.md`
</details>

<details>
<summary><b>What about 4G/LTE support?</b></summary>

Open5GS supports both 4G and 5G. Additional components needed:
- MME (instead of AMF)
- SGW-C, SGW-U (instead of SMF/UPF for 4G)
- HSS (instead of UDM/UDR)

Contact us for 4G deployment guides.
</details>

<details>
<summary><b>How do I scale to millions of subscribers?</b></summary>

1. Use MongoDB sharding/replication
2. Scale network functions horizontally
3. Deploy multiple UPFs for data plane
4. Use CDN for content delivery
5. Implement session stickiness
6. Consider distributed architecture

See `docs/high-scale-deployment.md`
</details>

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Reporting Issues

1. Check existing issues first
2. Provide detailed description
3. Include logs and configurations
4. Specify environment details

### Pull Requests

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/devopswihnaveen/open5g.git
cd open5gs-devops

# Add upstream
git remote add upstream https://github.com/original/open5gs-devops.git

# Create branch
git checkout -b feature/my-feature

# Make changes and test
make test

# Commit and push
git commit -am "Add feature"
git push origin feature/my-feature
```

### Code Style

- Use consistent indentation (2 spaces for YAML, 4 for Python)
- Add comments for complex logic
- Update documentation for new features
- Write meaningful commit messages

---

## 📄 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

```
Copyright 2024 Open5GS DevOps Contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 📞 Support

### Community Support

- **Documentation**: [Full docs](./docs/)
- **GitHub Issues**: [Report bugs](https://github.com/devopswihnaveen/open5g/issues)
- **Discussions**: [GitHub Discussions](https://github.com/devopswihnaveen/open5g/discussions)
- **Slack**: [Join our workspace](https://app.slack.com/client/T05D4HBK0H4/D0A6NCCGNLF)

### Professional Support

For commercial support, consulting, or custom development:
- **Email**: devops@example.com
- **Website**: https://example.com/open5gs-support

### Useful Links

- [Open5GS Official Docs](https://open5gs.org/open5gs/docs/)
- [3GPP Specifications](https://www.3gpp.org/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)

---

## 🙏 Acknowledgments

- **Open5GS Team** - For the amazing 5G core implementation
- **Kubernetes Community** - For orchestration excellence
- **HashiCorp** - For Terraform
- **AWS** - For cloud infrastructure
- **Contributors** - Everyone who has contributed to this project

---

## 📈 Project Status

- ✅ **Production Ready**: Tested with real workloads
- ✅ **Actively Maintained**: Regular updates and bug fixes
- ✅ **Well Documented**: Comprehensive guides
- ✅ **Community Driven**: Open to contributions

**Current Version**: 1.0.0
**Last Updated**: February 2024
**Open5GS Version**: 2.7.x
**Kubernetes Version**: 1.28+

---

## 🗺️ Roadmap

### Q1 2024
- [x] Initial release with AWS support
- [x] Helm charts
- [x] CI/CD pipelines
- [x] Monitoring stack

### Q2 2024
- [ ] Multi-cloud support (GCP, Azure)
- [ ] Advanced monitoring dashboards
- [ ] Performance testing suite
- [ ] Operator pattern implementation

### Q3 2024
- [ ] Service mesh integration (Istio)
- [ ] Multi-region deployment
- [ ] Disaster recovery automation
- [ ] Advanced security features

### Q4 2024
- [ ] AI-powered auto-tuning
- [ ] Cost optimization tools
- [ ] Compliance certifications
- [ ] Enterprise features

---

<div align="center">

**Made with ❤️ by the Open5GS DevOps Community**

[⬆ Back to Top](#open5gs-devops---production-deployment-guide)

</div>