# Quick Start Guide - Open5GS DevOps

Get Open5GS running in production in under 30 minutes!

## Prerequisites Check

```bash
# Make sure you have these installed:
terraform --version  # >= 1.5.0
kubectl version     # >= 1.28
helm version        # >= 3.13
docker --version    # >= 24.0
aws --version       # >= 2.x
```

## Step-by-Step Deployment

### 1. Clone and Setup (2 minutes)

```bash
git clone <repository-url>
cd open5gs-devops
make check-deps
```

### 2. AWS Configuration (3 minutes)

```bash
# Configure AWS credentials
aws configure

# Create Terraform state backend
aws s3 mb s3://open5gs-terraform-state
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### 3. Deploy Infrastructure (15 minutes)

```bash
# Option A: Using Make
make init
make tf-plan
make tf-apply

# Option B: Using script
./scripts/deploy.sh infra
```

### 4. Build and Deploy Application (10 minutes)

```bash
# Option A: All-in-one deployment
make deploy

# Option B: Step by step
make docker-push
make helm-install
make monitoring-install
```

### 5. Verify Deployment (2 minutes)

```bash
# Check all resources
make k8s-status

# Run smoke tests
make smoke-test

# Get WebUI URL
kubectl get svc open5gs-webui -n open5gs
```

## Access Your Deployment

### WebUI
```bash
# Get LoadBalancer URL
kubectl get svc open5gs-webui -n open5gs -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or port-forward for local access
kubectl port-forward svc/open5gs-webui 3000:3000 -n open5gs
# Access: http://localhost:3000
```

### Grafana Dashboard
```bash
make monitoring-forward
# Access: http://localhost:3000
# Default: admin / admin123
```

## Common Commands

```bash
# View logs
make k8s-logs

# Backup database
make backup

# Scale AMF
kubectl scale deployment open5gs-amf --replicas=5 -n open5gs

# Update configuration
kubectl edit configmap open5gs-amf-config -n open5gs
kubectl rollout restart deployment open5gs-amf -n open5gs
```

## Configuration Examples

### Update PLMN

Edit `helm/open5gs/values.yaml`:
```yaml
amf:
  config:
    guami:
      plmn_id:
        mcc: "001"  # Change this
        mnc: "01"   # Change this
```

Apply:
```bash
make helm-upgrade
```

### Add More Replicas

```bash
# Edit values file
vi helm/open5gs/values.yaml

# Change replicaCount
amf:
  replicaCount: 5

# Apply
make helm-upgrade
```

## Troubleshooting Quick Fixes

### Pods not starting?
```bash
kubectl describe pod <pod-name> -n open5gs
kubectl logs <pod-name> -n open5gs
```

### Network issues?
```bash
kubectl run -it --rm debug --image=nicolaka/netshoot -n open5gs -- bash
nslookup open5gs-nrf
curl http://open5gs-nrf:7777
```

### Need to reset?
```bash
make destroy
make deploy
```

## Next Steps

1. **Configure Security**: Review `docs/security-hardening.md`
2. **Setup CI/CD**: Configure GitHub Actions or GitLab CI
3. **Enable Monitoring**: Access Grafana dashboards
4. **Setup Backups**: Schedule automated backups
5. **Performance Tuning**: Adjust resource limits based on load

## Support

- Documentation: `README.md`
- Issues: Open a GitHub issue
- Email: devops@example.com

## Cost Estimation

Approximate AWS costs for production setup:
- EKS Cluster: ~$75/month
- EC2 Nodes (3x t3.xlarge): ~$300/month
- EBS Storage: ~$50/month
- Data Transfer: Variable
- **Total**: ~$425-500/month

To reduce costs:
- Use Spot instances for workload nodes
- Right-size instance types
- Enable cluster autoscaler
- Delete unused resources

---

**Ready to deploy? Run:**
```bash
make deploy
```
