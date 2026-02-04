# 🚀 Quick Start Guide - Open5GS DevOps

<div align="center">

**Deploy a Production-Ready 5G Core Network in 30 Minutes**

![Open5GS](https://img.shields.io/badge/Open5GS-5G%20Core-blue)
![Time](https://img.shields.io/badge/Time-30%20minutes-green)
![Difficulty](https://img.shields.io/badge/Difficulty-Beginner-brightgreen)

[Prerequisites](#-prerequisites) • [Installation](#-installation-steps) • [Verify](#-verify-deployment) • [Next Steps](#-next-steps)

</div>

---

## 📖 What You'll Achieve

By the end of this guide, you will have:

- ✅ A fully functional 5G Core Network running on AWS
- ✅ Kubernetes cluster managing all network functions
- ✅ MongoDB database for subscriber data
- ✅ Web UI for managing subscribers
- ✅ Monitoring dashboards (Prometheus & Grafana)
- ✅ Automated backups configured

**Total Time:** ~30 minutes  
**Cost:** ~$15-20 for testing (can be deleted after)

---

## 🎯 Prerequisites

### What You Need Before Starting

#### 1. AWS Account
- **Have**: An active AWS account
- **Need**: Credit card for billing (free tier eligible for some resources)
- **Sign up**: [aws.amazon.com](https://aws.amazon.com)

#### 2. Your Computer Requirements
- **OS**: Linux, macOS, or Windows 10/11 with WSL2
- **RAM**: At least 8GB
- **Disk Space**: 20GB free
- **Internet**: Stable connection

#### 3. Tools Installed
Don't worry if you don't have these - we'll install them!

| Tool | What It Does | Check if Installed |
|------|--------------|-------------------|
| **AWS CLI** | Talk to AWS | `aws --version` |
| **Terraform** | Build cloud infrastructure | `terraform version` |
| **kubectl** | Manage Kubernetes | `kubectl version --client` |
| **Helm** | Install applications on Kubernetes | `helm version` |
| **Docker** | Run containers locally | `docker --version` |
| **Git** | Version control | `git --version` |

---

## 🛠️ Step 0: Install Required Tools

### For Ubuntu/Debian Linux

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install basic tools
sudo apt install -y curl wget git unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

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
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Verify installations
echo "Checking installations..."
aws --version && echo "✓ AWS CLI installed"
terraform version && echo "✓ Terraform installed"
kubectl version --client && echo "✓ kubectl installed"
helm version && echo "✓ Helm installed"
docker --version && echo "✓ Docker installed"
git --version && echo "✓ Git installed"
```

### For macOS

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install all tools at once
brew install awscli terraform kubectl helm git

# Install Docker Desktop
brew install --cask docker

# Start Docker Desktop
open /Applications/Docker.app

# Wait for Docker to start, then verify
echo "Checking installations..."
aws --version && echo "✓ AWS CLI installed"
terraform version && echo "✓ Terraform installed"
kubectl version --client && echo "✓ kubectl installed"
helm version && echo "✓ Helm installed"
docker --version && echo "✓ Docker installed"
git --version && echo "✓ Git installed"
```

### For Windows (WSL2)

```bash
# First, install WSL2 and Ubuntu from Microsoft Store
# Then open Ubuntu terminal and run:

# Follow the Ubuntu/Debian instructions above
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# ... (same as Ubuntu steps)

# For Docker, download Docker Desktop for Windows
# https://www.docker.com/products/docker-desktop
```

**Important for all platforms:** After installation, close and reopen your terminal!

---

## 📦 Step 1: Get the Code (2 minutes)

```bash
# Clone the repository
git clone https://github.com/yourusername/open5gs-devops.git
cd open5gs-devops

# Verify you have all files
ls -la
# You should see: docker/, kubernetes/, terraform/, helm/, scripts/, README.md, etc.
```

**What just happened?**
- You downloaded all the configuration files needed to deploy Open5GS
- Think of it like downloading a recipe with all the instructions

---

## 🔑 Step 2: Configure AWS (3 minutes)

### 2.1 Get Your AWS Credentials

1. **Login to AWS Console**: Go to [console.aws.amazon.com](https://console.aws.amazon.com)
2. **Create Access Keys**:
   - Click your name (top right) → **Security credentials**
   - Scroll down to **Access keys**
   - Click **Create access key**
   - Choose **CLI** → Click **Next** → Click **Create**
   - **IMPORTANT**: Save both keys somewhere safe!

### 2.2 Configure AWS CLI

```bash
# Run this command
aws configure

# It will ask you 4 questions:
```

**Question 1:** `AWS Access Key ID:`
```
Paste your Access Key ID (starts with AKIA...)
```

**Question 2:** `AWS Secret Access Key:`
```
Paste your Secret Access Key (long random string)
```

**Question 3:** `Default region name:`
```
us-east-1
(or your preferred region: us-west-2, eu-west-1, etc.)
```

**Question 4:** `Default output format:`
```
json
```

### 2.3 Verify AWS Configuration

```bash
# Test your connection
aws sts get-caller-identity

# You should see something like:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/yourname"
# }
```

**✓ Success!** If you see your account info, you're connected to AWS.

---

## 🏗️ Step 3: Create Terraform Backend (3 minutes)

**What's this?** Terraform needs a place to store its state (like a save file for a game).

```bash
# Create S3 bucket (storage for Terraform state)
aws s3 mb s3://open5gs-terraform-state-$(date +%s) --region us-east-1

# Note: We add timestamp to make bucket name unique
# Save the bucket name! You'll need it in the next step.
```

**Example output:**
```
make_bucket: open5gs-terraform-state-1704901234
```

```bash
# Create DynamoDB table (prevents multiple people changing infrastructure at once)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

**What you created:**
- 🪣 S3 Bucket: Stores Terraform's memory
- 🔒 DynamoDB Table: Locks state so only one person can make changes at a time

### Update Terraform Configuration

```bash
# Edit the backend configuration
nano terraform/main.tf

# Find this section:
#   backend "s3" {
#     bucket         = "open5gs-terraform-state"
#     ...
#   }

# Replace "open5gs-terraform-state" with YOUR bucket name from above
# Save and exit (Ctrl+X, then Y, then Enter)
```

---

## 🚀 Step 4: Deploy Infrastructure (10 minutes)

**What happens here?** Terraform will create:
- Virtual Private Cloud (VPC) - Your private network in AWS
- Kubernetes Cluster (EKS) - Where Open5GS will run
- Virtual Machines (EC2) - The computers that run your containers
- Storage, Networking, Security - Everything needed

### 4.1 Check What Will Be Created

```bash
cd terraform

# Initialize Terraform
terraform init
```

**You should see:**
```
Terraform has been successfully initialized!
```

```bash
# See what will be created
terraform plan
```

**This shows you everything Terraform will create. Look for:**
- `Plan: X to add, 0 to change, 0 to destroy`
- X should be around 50-70 resources

### 4.2 Create the Infrastructure

```bash
# Create everything (this takes 10-15 minutes)
terraform apply

# Type 'yes' when asked to confirm
```

**What to expect:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes    ← Type this

...
Apply complete! Resources: 56 added, 0 changed, 0 destroyed.

Outputs:

eks_cluster_name = "open5gs-prod"
configure_kubectl = "aws eks update-kubeconfig --region us-east-1 --name open5gs-prod"
```

**☕ This is a good time for a coffee break!** (10-15 minutes)

### 4.3 Configure kubectl to Access Your Cluster

```bash
# Copy the command from Terraform output, or run:
aws eks update-kubeconfig --region us-east-1 --name open5gs-prod

# Verify connection
kubectl get nodes
```

**You should see:**
```
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.ec2.internal   Ready    <none>   2m    v1.28.x
ip-10-0-2-234.ec2.internal   Ready    <none>   2m    v1.28.x
ip-10-0-3-345.ec2.internal   Ready    <none>   2m    v1.28.x
```

**✓ Success!** You have a Kubernetes cluster running!

---

## 📱 Step 5: Deploy Open5GS (8 minutes)

### 5.1 Build and Push Docker Image

**Option A: Quick Method (Use Pre-built Image)**

We'll configure to use a pre-built image:

```bash
cd ../helm/open5gs

# Edit values.yaml
nano values.yaml

# Find all lines with "image:" and "repository:"
# Change: repository: open5gs
# To:     repository: docker.io/gradiant/open5gs
# Save and exit
```

**Option B: Build Your Own (Takes longer)**

```bash
cd ../../docker

# Get ECR repository URL
export ECR_REPO=$(aws ecr describe-repositories \
  --repository-names "open5gs/prod" \
  --query 'repositories[0].repositoryUri' \
  --output text 2>/dev/null)

# If empty, create repository
if [ -z "$ECR_REPO" ]; then
  aws ecr create-repository --repository-name "open5gs/prod"
  export ECR_REPO=$(aws ecr describe-repositories \
    --repository-names "open5gs/prod" \
    --query 'repositories[0].repositoryUri' \
    --output text)
fi

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REPO

# Build image (this takes 10-15 minutes)
docker build -t open5gs:latest -f Dockerfile .

# Tag and push
docker tag open5gs:latest $ECR_REPO:latest
docker push $ECR_REPO:latest
```

### 5.2 Deploy with Helm

```bash
cd ../helm

# Install Open5GS
helm upgrade --install open5gs ./open5gs \
  --namespace open5gs \
  --create-namespace \
  --values ./open5gs/values.yaml \
  --wait \
  --timeout 10m
```

**What you'll see:**
```
Release "open5gs" does not exist. Installing it now.
NAME: open5gs
LAST DEPLOYED: Mon Jan 15 10:30:00 2024
NAMESPACE: open5gs
STATUS: deployed
REVISION: 1
```

---

## ✅ Step 6: Verify Deployment (3 minutes)

### 6.1 Check All Pods Are Running

```bash
# Watch pods starting up
kubectl get pods -n open5gs -w

# Press Ctrl+C when all show "Running"
```

**What you should see:**
```
NAME                            READY   STATUS    RESTARTS   AGE
mongodb-0                       1/1     Running   0          2m
open5gs-amf-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-ausf-xxxxx-xxxxx       1/1     Running   0          2m
open5gs-bsf-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-nrf-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-nssf-xxxxx-xxxxx       1/1     Running   0          2m
open5gs-pcf-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-smf-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-udm-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-udr-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-upf-xxxxx-xxxxx        1/1     Running   0          2m
open5gs-webui-xxxxx-xxxxx      1/1     Running   0          2m
```

**✓ All pods should show `1/1 Running`**

### 6.2 Check Services

```bash
kubectl get svc -n open5gs
```

**You should see:**
```
NAME              TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)
mongodb           ClusterIP      None             <none>                                                                   27017/TCP
open5gs-amf       ClusterIP      10.100.x.x       <none>                                                                   7777/TCP,38412/SCTP
open5gs-nrf       ClusterIP      10.100.x.x       <none>                                                                   7777/TCP
open5gs-smf       ClusterIP      10.100.x.x       <none>                                                                   7777/TCP
open5gs-upf       ClusterIP      10.100.x.x       <none>                                                                   8805/UDP
open5gs-webui     LoadBalancer   10.100.x.x       a1234567890abcdef.us-east-1.elb.amazonaws.com                          3000:30000/TCP
```

### 6.3 Access the Web UI

```bash
# Get WebUI URL
export WEBUI_URL=$(kubectl get svc open5gs-webui -n open5gs \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "WebUI URL: http://$WEBUI_URL:3000"
```

**Open this URL in your browser!**

**Default Login:**
- Username: `admin`
- Password: `1423`

**🎉 Congratulations! You can now see the Open5GS Web Interface!**

### 6.4 Run Health Check

```bash
# Quick health check
kubectl get pods -n open5gs | grep -c "Running"
# Should show 12 (all pods running)

# Detailed check
kubectl get all -n open5gs
```

---

## 📊 Step 7: Install Monitoring (5 minutes)

**Why?** See real-time metrics, CPU usage, memory, and network traffic.

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install monitoring stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123 \
  --wait
```

**Wait for pods to start:**
```bash
kubectl get pods -n monitoring -w
# Press Ctrl+C when all are Running
```

### Access Grafana Dashboard

```bash
# Port forward Grafana to your computer
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Open in browser:** http://localhost:3000

**Login:**
- Username: `admin`
- Password: `admin123`

**What you can see:**
- 📈 Real-time CPU and Memory usage
- 📊 Network traffic
- 🔍 Pod status
- ⚡ Performance metrics

---

## 🎯 What Just Happened? (Summary)

Let's review what you built:

### Your Infrastructure

```
┌─────────────────────────────────────────────┐
│              AWS Cloud                      │
│  ┌───────────────────────────────────────┐  │
│  │         Kubernetes Cluster            │  │
│  │                                       │  │
│  │  ┌─────────────────────────────────┐ │  │
│  │  │    Open5GS Components           │ │  │
│  │  │                                 │ │  │
│  │  │  • NRF  - Service Discovery     │ │  │
│  │  │  • AMF  - Access Management     │ │  │
│  │  │  • SMF  - Session Management    │ │  │
│  │  │  • UPF  - User Plane (Data)     │ │  │
│  │  │  • AUSF - Authentication        │ │  │
│  │  │  • UDM  - User Data             │ │  │
│  │  │  • UDR  - Data Repository       │ │  │
│  │  │  • PCF  - Policy Control        │ │  │
│  │  │  • NSSF - Network Slicing       │ │  │
│  │  │  • BSF  - Binding Support       │ │  │
│  │  │                                 │ │  │
│  │  │  • MongoDB - Database           │ │  │
│  │  │  • WebUI   - Management         │ │  │
│  │  └─────────────────────────────────┘ │  │
│  │                                       │  │
│  │  ┌─────────────────────────────────┐ │  │
│  │  │    Monitoring                   │ │  │
│  │  │  • Prometheus - Metrics         │ │  │
│  │  │  • Grafana    - Dashboards      │ │  │
│  │  └─────────────────────────────────┘ │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Resource Count

- ☁️ **1 VPC** (Virtual Private Cloud)
- 🖥️ **3 EC2 Instances** (Virtual machines)
- 🎛️ **1 EKS Cluster** (Kubernetes)
- 🗄️ **1 MongoDB Database**
- 📱 **10 Network Functions** (5G Core components)
- 🌐 **1 Load Balancer** (For WebUI access)
- 📊 **Monitoring Stack** (Prometheus + Grafana)

---

## 🧪 Test Your Deployment

### Test 1: Check Network Function Discovery

```bash
# NRF should show registered network functions
kubectl logs -l app=open5gs-nrf -n open5gs --tail=50
```

**Look for lines like:**
```
[nrf] INFO: [Added] Number of NF registered=1
[nrf] INFO: [Added] Number of NF registered=2
...
```

### Test 2: Add a Test Subscriber

1. **Open WebUI** (from Step 6.3)
2. **Click** "Subscribers" in menu
3. **Click** "+ New Subscriber"
4. **Fill in:**
   - IMSI: `001010000000001`
   - Subscriber Key (K): `465B5CE8B199B49FAA5F0A2EE238A6BC`
   - OP: `E8ED289DEBA952E4283B54E88E6183CA`
5. **Click** "SAVE"

**✓ Success!** You added your first subscriber!

### Test 3: View Metrics

```bash
# Port forward Grafana (if not already running)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

1. **Open** http://localhost:3000
2. **Login** (admin/admin123)
3. **Click** "Dashboards" → "Browse"
4. **Select** "Kubernetes / Compute Resources / Namespace (Pods)"
5. **Choose** namespace: `open5gs`

**You should see:** Real-time graphs of CPU, Memory, and Network usage!

---

## 💡 Common First-Time Issues

### Issue 1: Pods Stuck in "Pending"

**Symptoms:**
```bash
kubectl get pods -n open5gs
# Shows: Pending
```

**Solution:**
```bash
# Check why
kubectl describe pod <pod-name> -n open5gs

# Usually: Not enough resources
# Fix: Wait for nodes to be ready, or increase node count
```

### Issue 2: Can't Access WebUI

**Symptoms:** LoadBalancer URL doesn't work

**Solution:**
```bash
# Check if LoadBalancer has an address
kubectl get svc open5gs-webui -n open5gs

# If EXTERNAL-IP shows <pending>, wait a few minutes
# AWS LoadBalancers take 2-3 minutes to provision

# Alternative: Use port-forward
kubectl port-forward svc/open5gs-webui 3000:3000 -n open5gs
# Then access: http://localhost:3000
```

### Issue 3: Terraform Error "Bucket Already Exists"

**Symptoms:** `BucketAlreadyExists` error

**Solution:**
```bash
# S3 bucket names must be globally unique
# Add your initials or timestamp:
aws s3 mb s3://open5gs-terraform-state-yourname-$(date +%s)
```

### Issue 4: AWS Credentials Error

**Symptoms:** `Unable to locate credentials`

**Solution:**
```bash
# Reconfigure AWS
aws configure

# Or check current config
cat ~/.aws/credentials
cat ~/.aws/config
```

---

## 🧹 Cleanup (Stop Paying)

**IMPORTANT:** Remember to clean up to avoid charges!

### Quick Cleanup (5 minutes)

```bash
# Delete Open5GS
helm uninstall open5gs -n open5gs

# Delete monitoring
helm uninstall prometheus -n monitoring

# Delete infrastructure
cd terraform
terraform destroy

# Type 'yes' when asked
```

### Verify Cleanup

```bash
# Check no EC2 instances running
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=Open5GS" \
  --query 'Reservations[].Instances[].State.Name'

# Check no LoadBalancers
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `open5gs`)].LoadBalancerName'

# Delete S3 bucket (if you want)
aws s3 rb s3://open5gs-terraform-state-XXXXX --force
```

---

## 📚 Next Steps

Now that you have Open5GS running, here's what to do next:

### 1. Learn More About Each Component

```bash
# View component logs
kubectl logs -f deployment/open5gs-amf -n open5gs   # Access Management
kubectl logs -f deployment/open5gs-smf -n open5gs   # Session Management
kubectl logs -f deployment/open5gs-upf -n open5gs   # User Plane
```

### 2. Add More Subscribers

- Open WebUI
- Go to "Subscribers"
- Add multiple test subscribers
- Each needs unique IMSI

### 3. Customize Configuration

```bash
# Edit network configuration
kubectl edit configmap open5gs-amf-config -n open5gs

# Change PLMN (Mobile Country/Network Code)
# Restart to apply
kubectl rollout restart deployment open5gs-amf -n open5gs
```

### 4. Scale Network Functions

```bash
# Increase AMF replicas
kubectl scale deployment open5gs-amf --replicas=3 -n open5gs

# Watch scaling
kubectl get pods -n open5gs -w
```

### 5. Set Up Automated Backups

```bash
# Run backup
cd scripts
./backup.sh backup

# Schedule with cron
crontab -e
# Add: 0 2 * * * /path/to/scripts/backup.sh backup
```

### 6. Connect Real Devices

**You'll need:**
- A gNB (5G base station) or eNB (4G base station)
- SIM cards programmed with matching IMSI/K/OP
- Proper network routing

**See:** Full guide in `docs/ue-connectivity.md`

### 7. Explore Monitoring

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Try these dashboards:
# - Kubernetes / Compute Resources
# - Prometheus / Stats
# - Create custom dashboard for Open5GS metrics
```

### 8. Read Full Documentation

- **README.md** - Complete reference guide
- **docs/architecture.md** - Detailed architecture
- **docs/troubleshooting.md** - Advanced troubleshooting
- **docs/security.md** - Security hardening

---

## 🎓 Learning Resources

### Understanding 5G Core

- **3GPP Specs**: [3gpp.org](https://www.3gpp.org/)
- **Open5GS Docs**: [open5gs.org/docs](https://open5gs.org/open5gs/docs/)
- **5G Architecture**: Search "5G Service-Based Architecture"

### Understanding Kubernetes

- **Official Tutorial**: [kubernetes.io/docs/tutorials](https://kubernetes.io/docs/tutorials/)
- **Interactive Learning**: [katacoda.com/kubernetes](https://www.katacoda.com/courses/kubernetes)

### Understanding Terraform

- **HashiCorp Learn**: [learn.hashicorp.com/terraform](https://learn.hashicorp.com/terraform)
- **AWS Provider Docs**: [registry.terraform.io/providers/hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## 💬 Get Help

### Something Not Working?

1. **Check the logs:**
   ```bash
   kubectl logs -l app.kubernetes.io/name=open5gs -n open5gs --tail=100
   ```

2. **Describe the pod:**
   ```bash
   kubectl describe pod <pod-name> -n open5gs
   ```

3. **Check events:**
   ```bash
   kubectl get events -n open5gs --sort-by='.lastTimestamp'
   ```

### Still Stuck?

- 💬 **GitHub Issues**: [github.com/yourrepo/issues](https://github.com/devopswihnaveen/open5g/issues)
- 📧 **Email**: naveenkumarvelanati@gmail.com
- 💬 **Slack**: [Join our workspace](https://app.slack.com/client/T05D4HBK0H4/D0A6NCCGNLF)
- 📖 **Documentation**: Check README.md for detailed guides

### Before Asking for Help

Please include:
1. What command you ran
2. What error you got
3. Output of `kubectl get pods -n open5gs`
4. Relevant logs

---

## ✨ Success Checklist

- [ ] All tools installed (AWS CLI, Terraform, kubectl, Helm, Docker)
- [ ] AWS configured with access keys
- [ ] Terraform backend created (S3 + DynamoDB)
- [ ] Infrastructure deployed (VPC, EKS, EC2)
- [ ] kubectl connected to cluster
- [ ] Open5GS deployed with Helm
- [ ] All 12 pods running
- [ ] WebUI accessible
- [ ] Test subscriber added
- [ ] Monitoring installed
- [ ] Grafana accessible

**If all checked: 🎉 CONGRATULATIONS! You did it!**

---

## 💰 Cost Tracking

**Approximate Costs While Running:**

| Resource | Hourly | Daily | Monthly |
|----------|--------|-------|---------|
| EKS Cluster | $0.10 | $2.40 | $73 |
| 3x t3.xlarge | $0.50 | $12.00 | $366 |
| Load Balancer | $0.03 | $0.67 | $20 |
| NAT Gateway | $0.14 | $3.36 | $96 |
| Storage | $0.01 | $0.13 | $4 |
| **Total** | **~$0.78** | **~$18.56** | **~$559** |

**Remember:**
- These are estimates for us-east-1 region
- Actual costs may vary
- **Always delete resources when done testing!**
- Use AWS Cost Explorer to track actual spending

### Set Up Cost Alerts

```bash
# Create billing alarm (AWS CLI)
aws cloudwatch put-metric-alarm \
  --alarm-name "Open5GS-High-Cost" \
  --alarm-description "Alert when costs exceed $50" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold
```

---

## 🚦 Status Indicators

### Healthy System

```bash
kubectl get pods -n open5gs
```

**All pods should show:**
```
✓ READY: 1/1
✓ STATUS: Running
✓ RESTARTS: 0 (or low number)
```

### Warning Signs

❌ **STATUS: CrashLoopBackOff** - Pod keeps restarting
❌ **STATUS: Error** - Pod failed to start
❌ **STATUS: Pending** - Waiting for resources
❌ **RESTARTS: 10+** - Pod is unstable

**If you see these, check:**
```bash
kubectl describe pod <pod-name> -n open5gs
kubectl logs <pod-name> -n open5gs
```

---

## 🎯 What You've Learned

By completing this guide, you now know:

- ✅ How to set up AWS CLI and credentials
- ✅ How to use Terraform for infrastructure
- ✅ How to deploy to Kubernetes
- ✅ How to use Helm for application deployment
- ✅ How to monitor with Prometheus and Grafana
- ✅ Basic kubectl commands
- ✅ How to troubleshoot pods
- ✅ How to clean up cloud resources

**These skills are valuable for any cloud deployment!**

---

## 🏆 You're Ready!

You've successfully deployed a production-ready 5G Core Network!

### What's Next?

1. **Experiment**: Try scaling, updating, monitoring
2. **Learn**: Read the full documentation
3. **Contribute**: Found a bug? Open an issue!
4. **Share**: Help others on the same journey

### Questions?

Don't hesitate to ask! We're here to help.

---

<div align="center">

**Made with ❤️ for beginners**

Happy Learning! 🚀

[⬆ Back to Top](#-quick-start-guide---open5gs-devops)

</div>