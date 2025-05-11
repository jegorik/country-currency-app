# Makefile for Country Currency App
# Helps run common CI/CD tasks locally

.PHONY: init plan apply test validate compliance clean deploy-dev deploy-test deploy-prod

# Variables
ENV ?= dev
BACKEND_CONFIG ?= 

# Init, with optional backend config (useful for different environments)
init:
	@echo "Initializing Terraform..."
	@terraform init $(BACKEND_CONFIG)

# Plan changes for a specific environment
plan:
	@echo "Planning for $(ENV) environment..."
	@terraform plan -var-file=environments/$(ENV).tfvars -out=$(ENV).tfplan

# Apply changes for a specific environment
apply:
	@echo "Applying for $(ENV) environment..."
	@terraform apply $(ENV).tfplan

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
