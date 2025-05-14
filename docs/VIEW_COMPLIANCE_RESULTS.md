# Viewing Terraform Compliance Results

This guide explains how to view the results of the Terraform Compliance checks that run on pull requests in this project.

## Introduction

Terraform Compliance is a test framework that checks if your Terraform code meets predefined compliance rules. These rules are defined in BDD (Behavior-Driven Development) style feature files in the `compliance/` directory.

## How to View Results

### 1. Automated PR Comments

The most convenient way to see compliance results is through the automated comments on your pull request:

- After you create or update a PR that includes changes to Terraform files, the compliance workflow will run.
- When completed, it will automatically add a comment to your PR with:
  - ✅ **Success message** if all compliance checks passed
  - ⚠️ **Warning message** if any compliance issues were detected
  - Detailed output from the compliance check process
  - A link to the full workflow logs

### 2. GitHub Actions Workflow Logs

To view the complete details:

1. Go to the GitHub repository
2. Click on the "Actions" tab
3. Find the "Terraform Compliance Checks" workflow run that corresponds to your pull request
4. Click on it to see details
5. Expand the "Run Terraform Compliance" step to see the full output

### 3. Job Summary

For a quick overview:

1. Go to the specific workflow run (as described above)
2. Scroll down to the "Summary" section at the bottom of the job
3. This provides a high-level overview of whether checks passed or failed

## Understanding Compliance Results

### Common Messages

- **Feature:** Describes the compliance rule being tested
- **Scenario:** The specific scenario within that feature
- **Given/When/Then:** BDD-style steps defining the compliance check
- **PASS/FAIL:** The outcome of each check

### Example Output

```
Feature: Basic Security Controls
  In order to ensure security best practices
  As engineers
  We'll use Terraform to enforce security standards

  Scenario: Ensure all resources have proper tags
    Given I have resource that supports tags defined
    When it has tags
    Then it must contain tags: ["environment", "project"]
    ✓ PASS
```

## Fixing Compliance Issues

If your PR shows compliance issues:

1. Review the detailed output to understand what failed
2. Check the corresponding feature files in the `compliance/` directory to understand the requirements
3. Update your Terraform code to meet the requirements
4. Push your changes - the compliance workflow will run again automatically

## Further Information

For more details on the Terraform Compliance framework, see:

- [Project compliance documentation](./TERRAFORM_COMPLIANCE.md)
- [Official terraform-compliance documentation](https://terraform-compliance.com/)
