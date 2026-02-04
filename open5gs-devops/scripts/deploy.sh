#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${ENVIRONMENT:-prod}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local deps=("terraform" "kubectl" "helm" "aws" "docker")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install missing dependencies and try again."
        exit 1
    fi
    
    print_info "All dependencies are installed."
}

deploy_infrastructure() {
    print_info "Deploying infrastructure with Terraform..."
    
    cd "$PROJECT_ROOT/terraform"
    
    terraform init
    terraform plan -var="environment=$ENVIRONMENT" -out=tfplan
    
    read -p "Do you want to apply this plan? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        terraform apply tfplan
        print_info "Infrastructure deployed successfully."
    else
        print_warning "Terraform apply cancelled."
        exit 0
    fi
    
    cd "$PROJECT_ROOT"
}

configure_kubectl() {
    print_info "Configuring kubectl..."
    
    local cluster_name="open5gs-${ENVIRONMENT}"
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$cluster_name"
    
    print_info "kubectl configured successfully."
}

build_docker_image() {
    print_info "Building Docker image..."
    
    cd "$PROJECT_ROOT"
    
    # Get ECR repository URL
    local ecr_repo=$(aws ecr describe-repositories --repository-names "open5gs/${ENVIRONMENT}" --region "$AWS_REGION" --query 'repositories[0].repositoryUri' --output text)
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ecr_repo"
    
    # Build and push image
    local image_tag="$(git rev-parse --short HEAD)"
    docker build -t "${ecr_repo}:${image_tag}" -f docker/Dockerfile .
    docker tag "${ecr_repo}:${image_tag}" "${ecr_repo}:latest"
    docker push "${ecr_repo}:${image_tag}"
    docker push "${ecr_repo}:latest"
    
    print_info "Docker image built and pushed: ${ecr_repo}:${image_tag}"
}

deploy_with_helm() {
    print_info "Deploying Open5GS with Helm..."
    
    local chart_path="$PROJECT_ROOT/helm/open5gs"
    local values_file="$chart_path/values-${ENVIRONMENT}.yaml"
    
    if [ ! -f "$values_file" ]; then
        print_warning "Values file not found: $values_file"
        print_info "Using default values.yaml"
        values_file="$chart_path/values.yaml"
    fi
    
    helm upgrade --install open5gs "$chart_path" \
        --namespace open5gs \
        --create-namespace \
        --values "$values_file" \
        --wait \
        --timeout 15m
    
    print_info "Open5GS deployed successfully."
}

verify_deployment() {
    print_info "Verifying deployment..."
    
    # Check if all pods are running
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=open5gs -n open5gs --timeout=300s
    
    # Get service status
    kubectl get all -n open5gs
    
    # Get WebUI URL
    local webui_url=$(kubectl get svc open5gs-webui -n open5gs -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -n "$webui_url" ]; then
        print_info "WebUI is accessible at: http://${webui_url}:3000"
    fi
    
    print_info "Deployment verification completed."
}

setup_monitoring() {
    print_info "Setting up monitoring..."
    
    # Install Prometheus
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --wait
    
    print_info "Monitoring setup completed."
}

cleanup() {
    print_warning "Cleaning up resources..."
    
    read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        # Uninstall Helm releases
        helm uninstall open5gs -n open5gs || true
        helm uninstall prometheus -n monitoring || true
        
        # Destroy infrastructure
        cd "$PROJECT_ROOT/terraform"
        terraform destroy -var="environment=$ENVIRONMENT" -auto-approve
        
        print_info "Cleanup completed."
    else
        print_warning "Cleanup cancelled."
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "Open5GS Deployment Script"
    echo "========================="
    echo "Environment: $ENVIRONMENT"
    echo "AWS Region: $AWS_REGION"
    echo ""
    echo "1. Check dependencies"
    echo "2. Deploy infrastructure (Terraform)"
    echo "3. Build and push Docker image"
    echo "4. Deploy Open5GS (Helm)"
    echo "5. Verify deployment"
    echo "6. Setup monitoring"
    echo "7. Full deployment (All steps)"
    echo "8. Cleanup/Destroy"
    echo "9. Exit"
    echo ""
    read -p "Select an option: " option
    
    case $option in
        1) check_dependencies ;;
        2) deploy_infrastructure ;;
        3) build_docker_image ;;
        4) 
            configure_kubectl
            deploy_with_helm
            ;;
        5) verify_deployment ;;
        6) setup_monitoring ;;
        7)
            check_dependencies
            deploy_infrastructure
            configure_kubectl
            build_docker_image
            deploy_with_helm
            verify_deployment
            setup_monitoring
            ;;
        8) cleanup ;;
        9) exit 0 ;;
        *) 
            print_error "Invalid option"
            show_menu
            ;;
    esac
}

# Check if running with arguments
if [ $# -eq 0 ]; then
    show_menu
else
    case "$1" in
        check) check_dependencies ;;
        infra) deploy_infrastructure ;;
        build) build_docker_image ;;
        deploy) 
            configure_kubectl
            deploy_with_helm
            ;;
        verify) verify_deployment ;;
        monitor) setup_monitoring ;;
        full)
            check_dependencies
            deploy_infrastructure
            configure_kubectl
            build_docker_image
            deploy_with_helm
            verify_deployment
            setup_monitoring
            ;;
        cleanup) cleanup ;;
        *)
            print_error "Unknown command: $1"
            echo "Usage: $0 [check|infra|build|deploy|verify|monitor|full|cleanup]"
            exit 1
            ;;
    esac
fi
