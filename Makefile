# Makefile for Country Currency App
# Helps run common CI/CD tasks locally

.PHONY: init plan apply test validate compliance clean deploy-dev deploy-test deploy-prod streamlit-app install-streamlit

# Variables
ENV ?= dev
BACKEND_CONFIG ?= 

# Init, with optional backend config (useful for different environments)
init:
	@echo "Initializing Terraform..."
	@cd terraform && terraform init $(BACKEND_CONFIG)

# Plan changes for a specific environment
plan:
	@echo "Planning for $(ENV) environment..."
	@cd terraform && terraform plan -var-file=../environments/$(ENV).tfvars -out=$(ENV).tfplan

# Apply changes for a specific environment
apply:
	@echo "Applying for $(ENV) environment..."
	@cd terraform && terraform apply $(ENV).tfplan

# Run tests
test:
	@echo "Running tests..."
	@python -m pytest tests/ -v

# Validate all Terraform files
validate:
	@echo "Validating Terraform files..."
	@terraform validate
	@terraform fmt -check -recursive

# Run Terraform compliance checks
compliance: plan
	@echo "Running compliance checks..."
	@terraform show -json $(ENV).tfplan > $(ENV)-plan.json
	@terraform-compliance -f compliance/ -p $(ENV)-plan.json || echo "Compliance check failed!"

# Clean up generated files
clean:
	@echo "Cleaning up..."
	@rm -f *.tfplan
	@rm -f *.tfplan.json

# Deploy shortcuts for different environments
deploy-dev: init
	@make ENV=dev plan
	@make ENV=dev apply

deploy-test: init
	@make ENV=test plan
	@make ENV=test apply

deploy-prod: init
	@echo "⚠️  WARNING: You are about to deploy to PRODUCTION!"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ]; then \
		make ENV=prod plan; \
		make ENV=prod apply; \
	else \
		echo "Production deployment aborted"; \
	fi

# Generate documentation
docs:
	@echo "Generating documentation..."
	@terraform-docs markdown . > TERRAFORM.md

# Lint all Python files
lint:
	@echo "Linting Python files..."
	@flake8 notebooks/ tests/ --max-line-length=120 --extend-ignore=E203

# Check for security issues
security-check:
	@echo "Running security checks..."
	@checkov -d . --framework terraform
	@bandit -r notebooks/

# Install Streamlit requirements
install-streamlit:
	@echo "Installing Streamlit app dependencies..."
	@cd streamlit && pip install -r requirements.txt

# Start the Streamlit application using unified launcher
streamlit-app: install-streamlit
	@echo "Starting Streamlit application using unified launcher..."
	@cd streamlit && bash unified_start_app.sh

# For now, keep the original wait-and-start scripts since they contain specific waiting logic
# We can unify them in a future update
wait-and-start-ui: install-streamlit
	@echo "Waiting for job to complete and then starting Streamlit app..."
ifeq ($(OS),Windows_NT)
	@cd streamlit && powershell -ExecutionPolicy Bypass -File wait_and_start.ps1
else
	@cd streamlit && bash wait_and_start.sh
endif

# Full deployment with Streamlit app (without waiting)
deploy-with-ui: deploy-dev streamlit-app

# Full deployment with waiting for job completion
deploy-and-wait: deploy-dev wait-and-start-ui
# OS agnostic deployment target for Makefile
# Simplified deployment using unified scripts

# Detect OS and set appropriate execute command
ifeq ($(OS),Windows_NT)
	EXEC_CMD = powershell.exe -ExecutionPolicy Bypass -File
	DEPLOY_SCRIPT = scripts\unified_deploy.ps1
else
	EXEC_CMD = bash
	DEPLOY_SCRIPT = scripts/unified_deploy.sh
endif

# Deploy based on OS using unified deployment scripts
deploy:
	@echo "Deploying using unified deployment script..."
	@$(EXEC_CMD) $(DEPLOY_SCRIPT)
