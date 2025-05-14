# Documentation Inventory

This document provides a complete inventory of all documentation resources in the Country Currency App project. It was created as part of Phase 1 of the Documentation Review Plan on May 14, 2025.

## Documentation Categories

### 1. Project Overview Documentation
- `/README.md` - Main project overview and setup instructions
- `/docs/ARCHITECTURE.md` - System architecture description
- `/docs/COMPONENT_DIAGRAM.md` - Visual representation of system components

### 2. Technical Documentation
- `/docs/CI_CD.md` - CI/CD pipeline description
- `/docs/CI_CD_TESTING.md` - Testing strategies for CI/CD
- `/docs/MIGRATION.md` - Migration procedures and guidelines
- `/docs/NOTEBOOK_VALIDATION.md` - Notebook validation processes
- `/docs/PYTHON_COMPATIBILITY.md` - Python version compatibility information
- `/docs/PROJECT-CLEANUP.md` - Guidelines for project cleanup
- `/docs/OS-AGNOSTIC-CHANGES.md` - Cross-platform compatibility changes

### 3. User Guides
- `/docs/USER_GUIDE.md` - End user instructions
- `/docs/TROUBLESHOOTING.md` - Common issues and solutions
- `/docs/CONTRIBUTING.md` - Guidelines for contributors
- `/docs/SCRIPT_USAGE_GUIDE.md` - Detailed guide for running scripts from various locations

### 4. Component Documentation
- `/docs/STREAMLIT_APP.md` - Streamlit application documentation
- `/streamlit/README.md` - Streamlit component overview (application code)
- `/streamlit/ui/styles/README.md` - UI styling documentation
- `/scripts/streamlit/README.md` - Streamlit launcher scripts documentation

### 5. Script Documentation
- `/scripts/deploy/README.md` - Deployment scripts documentation
- `/scripts/setup/README.md` - Setup scripts documentation
- `/scripts/test/README.md` - Testing scripts documentation
- `/scripts/utils/README.md` - Utility scripts documentation

### 6. Configuration Documentation
- `/terraform/terraform.tfvars.example` - Example Terraform configuration
- `/streamlit/requirements.txt` - Streamlit application dependencies
- `/.env.example` - Environment variables template

### 7. GitHub Templates and Workflows
- `/.github/pull_request_template.md` - Default PR template
- `/.github/PULL_REQUEST_TEMPLATE/notebook_validation_fix.md` - Notebook validation PR template
- `/.github/ISSUE_TEMPLATE/feature_request.md` - Feature request template
- `/.github/ISSUE_TEMPLATE/bug_report.md` - Bug report template

### 8. Source Code Documentation
Key source files with significant documentation/comments:

#### Streamlit Application
- `/streamlit/app.py` - Main application entry point
- `/streamlit/models/country_currency.py` - Data models
- `/streamlit/operations/data_operations.py` - Data operations
- `/streamlit/utils/` - Utility modules
  - `app_utils.py`
  - `databricks_client.py` 
  - `logger.py`
  - `status_checker.py`
  - `utils.py`
- `/streamlit/ui/` - UI components
  - `main_view.py`
  - `sidebar.py`
  - `visualizations.py`
  - `crud_operations.py`
  - `filtering.py`
  - `data_display.py`
  - `crud_views.py`

#### Scripts
- `/scripts/streamlit/` - Streamlit launcher scripts
  - `unified_start_app.sh`
  - `wait_and_start.sh`
  - `wait_and_start.ps1`
  - `start_app.ps1`
- `/scripts/deploy/` - Deployment scripts
  - `unified_deploy.sh`
  - `unified_deploy.ps1`
  - `deploy_windows.ps1`
- `/scripts/test/` - Testing scripts
  - `run_tests.sh`
  - `validate_notebook.sh`
  - `test_databricks_connection.sh`
- `/scripts/setup/` - Setup scripts
  - `setup.sh`
  - `configure_databricks_cli.sh`
- `/scripts/utils/` - Utility scripts
  - `check_terraform_paths.sh`

## Key Observations

1. **Documentation Distribution**
   - Documentation is well-distributed across the project
   - Each component has appropriate documentation
   - Multiple README files provide context-specific guidance

2. **Documentation Coverage**
   - All major aspects of the project have dedicated documentation
   - Technical aspects are well-documented
   - User guides cover necessary end-user information

3. **Documentation Format**
   - Primarily Markdown format
   - Examples provided for configuration files
   - Inline documentation in source code

4. **Areas for Special Attention in Documentation Review**
   - Script paths after relocation from `/streamlit` to `/scripts/streamlit/`
   - Path references in documentation
   - Command examples using correct paths and directory structures
   - Cross-platform functionality (Windows/Unix compatibility)

This inventory will serve as the basis for the detailed documentation review in Phases 2-4 of the Documentation Review Plan.
