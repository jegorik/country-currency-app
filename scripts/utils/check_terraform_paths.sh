#!/bin/bash
# Script to check and report Terraform paths after project restructuring

echo "===== Terraform Path Check ====="
echo "Checking for Terraform path issues after project restructuring..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Files to check
echo -e "${YELLOW}Checking script files for terraform path issues...${NC}"

# List of files to check
FILES_TO_CHECK=(
  "$PROJECT_ROOT/scripts/setup/setup.sh"
  "$PROJECT_ROOT/scripts/test/validate_notebook.sh"
  "$PROJECT_ROOT/scripts/test/test_databricks_connection.sh"
  "$PROJECT_ROOT/scripts/test/run_tests.sh"
  "$PROJECT_ROOT/.github/workflows/terraform-compliance.yml"
  "$PROJECT_ROOT/.github/workflows/ci-cd.yml"
  "$PROJECT_ROOT/.github/workflows/release.yml"
)

# Patterns that might indicate wrong Terraform paths
PATTERNS=(
  "terraform init"
  "terraform plan"
  "terraform apply"
  "terraform output"
  "terraform validate"
  "terraform fmt"
  "terraform.tfvars"
  "terraform import"
)

for file in "${FILES_TO_CHECK[@]}"; do
  if [[ -f "$file" ]]; then
    echo -e "\n${YELLOW}Checking $file...${NC}"
    
    for pattern in "${PATTERNS[@]}"; do
      # Check if pattern exists in file
      if grep -q "$pattern" "$file"; then
        # Check if we're already in the terraform directory
        if grep -q "cd [^/]*/terraform" "$file" || grep -q "cd \"\$TERRAFORM_DIR\"" "$file" || grep -B2 "$pattern" "$file" | grep -q "cd.*terraform"; then
          echo -e "${GREEN}✓ $pattern - Path seems correct (cd to terraform dir found)${NC}"
        # Check if we're using a path to terraform directory
        elif grep -q "$pattern.*terraform/" "$file"; then
          echo -e "${GREEN}✓ $pattern - Path seems correct (terraform/ prefix found)${NC}"
        else
          echo -e "${RED}✗ $pattern - Possible wrong path${NC}"
          echo -e "  ${YELLOW}Lines:${NC}"
          grep -n -B1 -A1 "$pattern" "$file" | sed 's/^/    /'
          echo ""
        fi
      fi
    done
  else
    echo -e "${YELLOW}File not found: $file${NC}"
  fi
done

echo -e "\n${GREEN}Terraform path check complete!${NC}"
