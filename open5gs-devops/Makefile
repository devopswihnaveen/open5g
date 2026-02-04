.PHONY: help init build push deploy destroy clean test lint fmt validate

# Variables
PROJECT_NAME := open5gs
ENVIRONMENT := prod
AWS_REGION := us-east-1
DOCKER_REGISTRY := $(shell aws ecr describe-repositories --repository-names "$(PROJECT_NAME)/$(ENVIRONMENT)" --region $(AWS_REGION) --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")
IMAGE_TAG := $(shell git rev-parse --short HEAD)

# Colors
COLOR_RESET := \033[0m
COLOR_INFO := \033[36m
COLOR_SUCCESS := \033[32m
COLOR_WARNING := \033[33m

help: ## Show this help message
	@echo '$(COLOR_INFO)Open5GS DevOps Commands:$(COLOR_RESET)'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_SUCCESS)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'
	@echo ''

check-deps: ## Check if all required tools are installed
	@echo "$(COLOR_INFO)Checking dependencies...$(COLOR_RESET)"
	@command -v terraform >/dev/null 2>&1 || { echo "terraform not found"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "helm not found"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "aws-cli not found"; exit 1; }
	@echo "$(COLOR_SUCCESS)All dependencies are installed!$(COLOR_RESET)"

# Terraform Commands
tf-init: ## Initialize Terraform
	@echo "$(COLOR_INFO)Initializing Terraform...$(COLOR_RESET)"
	cd terraform && terraform init

tf-plan: tf-init ## Create Terraform plan
	@echo "$(COLOR_INFO)Creating Terraform plan...$(COLOR_RESET)"
	cd terraform && terraform plan -var="environment=$(ENVIRONMENT)" -out=tfplan

tf-apply: ## Apply Terraform configuration
	@echo "$(COLOR_INFO)Applying Terraform configuration...$(COLOR_RESET)"
	cd terraform && terraform apply tfplan

tf-destroy: ## Destroy Terraform infrastructure
	@echo "$(COLOR_WARNING)Destroying infrastructure...$(COLOR_RESET)"
	cd terraform && terraform destroy -var="environment=$(ENVIRONMENT)" -auto-approve

tf-fmt: ## Format Terraform files
	cd terraform && terraform fmt -recursive

tf-validate: tf-init ## Validate Terraform configuration
	cd terraform && terraform validate

# Docker Commands
docker-login: ## Login to ECR
	@echo "$(COLOR_INFO)Logging into ECR...$(COLOR_RESET)"
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(DOCKER_REGISTRY)

docker-build: ## Build Docker image
	@echo "$(COLOR_INFO)Building Docker image...$(COLOR_RESET)"
	docker build -t $(PROJECT_NAME):$(IMAGE_TAG) -f docker/Dockerfile .
	docker tag $(PROJECT_NAME):$(IMAGE_TAG) $(PROJECT_NAME):latest

docker-push: docker-login docker-build ## Build and push Docker image
	@echo "$(COLOR_INFO)Pushing Docker image...$(COLOR_RESET)"
	docker tag $(PROJECT_NAME):$(IMAGE_TAG) $(DOCKER_REGISTRY):$(IMAGE_TAG)
	docker tag $(PROJECT_NAME):$(IMAGE_TAG) $(DOCKER_REGISTRY):latest
	docker push $(DOCKER_REGISTRY):$(IMAGE_TAG)
	docker push $(DOCKER_REGISTRY):latest

# Kubernetes Commands
k8s-config: ## Configure kubectl
	@echo "$(COLOR_INFO)Configuring kubectl...$(COLOR_RESET)"
	aws eks update-kubeconfig --region $(AWS_REGION) --name $(PROJECT_NAME)-$(ENVIRONMENT)

k8s-apply: ## Apply Kubernetes manifests
	@echo "$(COLOR_INFO)Applying Kubernetes manifests...$(COLOR_RESET)"
	kubectl apply -f kubernetes/00-namespace.yaml
	kubectl apply -f kubernetes/01-configmaps.yaml
	kubectl apply -f kubernetes/02-mongodb.yaml
	kubectl apply -f kubernetes/03-deployments.yaml
	kubectl apply -f kubernetes/04-hpa.yaml

k8s-delete: ## Delete Kubernetes resources
	@echo "$(COLOR_WARNING)Deleting Kubernetes resources...$(COLOR_RESET)"
	kubectl delete -f kubernetes/ || true

k8s-status: ## Check Kubernetes resources status
	@echo "$(COLOR_INFO)Checking resource status...$(COLOR_RESET)"
	kubectl get all -n $(PROJECT_NAME)

k8s-logs: ## Tail logs from all pods
	kubectl logs -f -l app.kubernetes.io/name=$(PROJECT_NAME) -n $(PROJECT_NAME) --all-containers=true

# Helm Commands
helm-lint: ## Lint Helm charts
	@echo "$(COLOR_INFO)Linting Helm charts...$(COLOR_RESET)"
	helm lint helm/$(PROJECT_NAME)

helm-template: ## Template Helm chart
	helm template $(PROJECT_NAME) helm/$(PROJECT_NAME) --values helm/$(PROJECT_NAME)/values.yaml

helm-install: ## Install Helm chart
	@echo "$(COLOR_INFO)Installing Helm chart...$(COLOR_RESET)"
	helm upgrade --install $(PROJECT_NAME) helm/$(PROJECT_NAME) \
		--namespace $(PROJECT_NAME) \
		--create-namespace \
		--values helm/$(PROJECT_NAME)/values-$(ENVIRONMENT).yaml \
		--wait

helm-uninstall: ## Uninstall Helm chart
	@echo "$(COLOR_WARNING)Uninstalling Helm chart...$(COLOR_RESET)"
	helm uninstall $(PROJECT_NAME) -n $(PROJECT_NAME)

helm-upgrade: ## Upgrade Helm chart
	@echo "$(COLOR_INFO)Upgrading Helm chart...$(COLOR_RESET)"
	helm upgrade $(PROJECT_NAME) helm/$(PROJECT_NAME) \
		--namespace $(PROJECT_NAME) \
		--values helm/$(PROJECT_NAME)/values-$(ENVIRONMENT).yaml \
		--wait

# Monitoring Commands
monitoring-install: ## Install monitoring stack
	@echo "$(COLOR_INFO)Installing monitoring stack...$(COLOR_RESET)"
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring \
		--create-namespace \
		--wait

monitoring-forward: ## Port forward Grafana
	@echo "$(COLOR_INFO)Port forwarding Grafana to localhost:3000...$(COLOR_RESET)"
	kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Backup Commands
backup: ## Run backup
	@echo "$(COLOR_INFO)Running backup...$(COLOR_RESET)"
	./scripts/backup.sh backup

restore: ## Restore from backup (make restore BACKUP_FILE=path/to/backup.tar.gz)
	@echo "$(COLOR_INFO)Restoring from backup...$(COLOR_RESET)"
	./scripts/backup.sh restore $(BACKUP_FILE)

# Testing Commands
test: ## Run tests
	@echo "$(COLOR_INFO)Running tests...$(COLOR_RESET)"
	kubectl run -it --rm test-pod --image=nicolaka/netshoot --restart=Never -n $(PROJECT_NAME) -- /bin/bash

smoke-test: ## Run smoke tests
	@echo "$(COLOR_INFO)Running smoke tests...$(COLOR_RESET)"
	kubectl wait --for=condition=ready pod -l app=$(PROJECT_NAME)-nrf -n $(PROJECT_NAME) --timeout=300s
	kubectl wait --for=condition=ready pod -l app=$(PROJECT_NAME)-amf -n $(PROJECT_NAME) --timeout=300s

# Cleanup Commands
clean: ## Clean up local files
	@echo "$(COLOR_INFO)Cleaning up...$(COLOR_RESET)"
	rm -rf .terraform terraform/.terraform terraform/*.tfstate* terraform/tfplan
	docker system prune -af

# All-in-one Commands
deploy: check-deps docker-push helm-install monitoring-install ## Full deployment
	@echo "$(COLOR_SUCCESS)Deployment completed!$(COLOR_RESET)"

destroy: helm-uninstall tf-destroy ## Full cleanup
	@echo "$(COLOR_SUCCESS)Cleanup completed!$(COLOR_RESET)"

init: check-deps tf-init k8s-config ## Initialize everything
	@echo "$(COLOR_SUCCESS)Initialization completed!$(COLOR_RESET)"
