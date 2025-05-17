# Makefile for Country Currency App
# Helps run common CI/CD tasks locally

.PHONY: init plan apply test validate compliance clean deploy-dev deploy-test deploy-prod streamlit-app install-streamlit apply-existing update-existing

# Variables
ENV ?= dev
BACKEND_CONFIG ?= 
# Set to false by default - override with make SKIP_EXISTING=true
SKIP_EXISTING ?= false

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

# Apply changes skipping resources that might already exist
# Use: make apply-existing ENV=dev
apply-existing:
	@echo "⚙️  Applying for $(ENV) environment (skipping existing resources)..."
	@echo "   This will NOT attempt to create resources that may already exist in Databricks"
	@cd terraform && terraform apply \
		-var-file=../environments/$(ENV).tfvars \
		-var="create_schema=false" \
		-var="create_volume=false" \
		-var="create_table=false" \
		-var="upload_csv=false"

# Update existing environment (plan and apply with skip flags)
# Use: make update-existing ENV=dev
update-existing:
	@echo "🔄 Planning update for $(ENV) environment (skipping existing resources)..."
	@echo "   This is safe to use when resources already exist in Databricks"
	@cd terraform && terraform plan \
		-var-file=../environments/$(ENV).tfvars \
		-var="create_schema=false" \
		-var="create_volume=false" \
		-var="create_table=false" \
		-var="upload_csv=false" \
		-out=$(ENV)_update.tfplan
	@echo "✅ Applying update for $(ENV) environment..."
	@cd terraform && terraform apply $(ENV)_update.tfplan

# Run tests
test:
	@echo "Running tests..."
	@bash scripts/test/run_tests.sh

# Validate notebooks
validate:
	@echo "Validating notebooks..."
	@python ci/validate_notebooks.py

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

#----------------------------------------------
# Databricks Resource Management
#----------------------------------------------

# Variable for the catalog name (default: main, override with CATALOG=your_catalog)
CATALOG ?= main

# List schemas in the specified catalog
list-schemas:
	@echo "📋 Listing schemas in catalog '$(CATALOG)'..."
	@databricks schemas list --catalog=$(CATALOG)

# List volumes in the specified schema (use: make list-volumes CATALOG=main SCHEMA=your_schema)
SCHEMA ?= country_currency
list-volumes:
	@echo "📂 Listing volumes in schema '$(CATALOG).$(SCHEMA)'..."
	@databricks volumes list --catalog=$(CATALOG) --schema=$(SCHEMA)
	
# List tables in the specified schema
list-tables:
	@echo "🗄️  Listing tables in schema '$(CATALOG).$(SCHEMA)'..."
	@databricks tables list --catalog=$(CATALOG) --schema=$(SCHEMA)

# Check if resources exist before deployment
check-resources: list-schemas list-volumes list-tables
	@echo "✅ Resource check complete."

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
	@bash scripts/streamlit/unified_start_app.sh

# Using the relocated wait-and-start scripts
wait-and-start-ui: install-streamlit
	@echo "Waiting for job to complete and then starting Streamlit app..."
ifeq ($(OS),Windows_NT)
	@powershell -ExecutionPolicy Bypass -File scripts/streamlit/wait_and_start.ps1
else
	@bash scripts/streamlit/wait_and_start.sh
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
	DEPLOY_SCRIPT = scripts\deploy\unified_deploy.ps1
else
	EXEC_CMD = bash
	DEPLOY_SCRIPT = scripts/deploy/unified_deploy.sh
endif

# Deploy based on OS using unified deployment scripts
deploy:
	@echo "Deploying using unified deployment script..."
	@$(EXEC_CMD) $(DEPLOY_SCRIPT)
