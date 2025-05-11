# Terraform Compliance Tests
# To run: terraform-compliance -f compliance/ -p tfplan

Feature: Resource Tagging Policy
  In order to have proper resource organization
  As engineers
  We ensure all resources have required tags

  Scenario: Ensure all resources have tags
    Given I have resource that supports tags defined
    Then it must contain tags
    And its tags must contain a key "environment"
    And its tags must contain a key "project"

Feature: Security Controls
  In order to protect sensitive information
  As the security team
  We need to ensure no secrets are exposed

  Scenario: No sensitive variables should be in plain text 
    Given I have variable defined
    When its name is "databricks_token"
    Then it must contain "sensitive" directive
    And its value must not match the "(dapi[0-9a-z]+)" regex

Feature: Environment Configuration
  In order to maintain consistent environments
  As DevOps engineers
  We need proper environment configurations

  Scenario: Environment must be a valid value
    Given I have variable defined
    When its name is "environment"
    Then it must contain "validation" directive
    And its validation condition must contain "contains(\["dev", "test", "prod"\], var.environment)"
