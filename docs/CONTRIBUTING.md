# Contributing to Country Currency App

Thank you for considering contributing to the Country Currency App! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project.

## How Can I Contribute?

### Reporting Bugs

If you find a bug in the project:

1. Check if the bug has already been reported in the issue tracker.
2. If not, create a new issue with a clear title and description.
3. Include steps to reproduce the bug and the expected behavior.
4. If possible, include screenshots or error logs.

### Suggesting Enhancements

If you have an idea for an enhancement:

1. Check if the enhancement has already been suggested in the issue tracker.
2. If not, create a new issue with a clear title and description.
3. Explain why this enhancement would be useful to most users.

### Pull Requests

1. Fork the repository.
2. Create a new branch from the `main` branch for your changes.
3. Make your changes, following the coding conventions below.
4. Test your changes.
5. Submit a pull request, describing the changes you've made.

## Development Setup

To set up a development environment:

1. Clone the repository.
2. Install prerequisites:
   - Terraform (v1.0.0+)
   - Databricks CLI
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and update it with your values.
4. Run `./setup.sh` to initialize the project.

## Coding Conventions

### Terraform

- Use consistent indentation (2 spaces).
- Use snake_case for naming resources, variables, and outputs.
- Group similar resources together.
- Add meaningful comments to explain complex configurations.
- Format Terraform code using `terraform fmt`.

### Python (Databricks Notebooks)

- Follow PEP 8 style guide.
- Add docstrings to functions and classes.
- Use meaningful variable and function names.
- Add comments to explain complex logic.

## Commit Messages

- Use clear and descriptive commit messages.
- Start with a short summary (50 chars or less).
- Follow with a more detailed description if necessary.
- Use the present tense ("Add feature" not "Added feature").
- Reference issue numbers in the commit message.

## Documentation

When making changes:

- Update the README.md if necessary.
- Update ARCHITECTURE.md if the architecture changes.
- Add comments to your code.
- Update any affected diagrams.

## Testing

Before submitting a pull request:

- Test your changes in a Databricks environment.
- Verify that existing functionality is not broken.
- Run `terraform validate` to check for errors.
- Run `terraform plan` to verify your changes.

## Review Process

All submissions require review. The project maintainers will review your code for:

- Functionality
- Code quality
- Documentation
- Test coverage

Thank you for your contributions!
