# Fixing GitHub Actions Release Workflow

## Issue
The GitHub Actions workflow for creating releases fails after merging from `dev` to `main` with the error:

```
Error: Unable to process file command 'env' successfully.
Error: Invalid format '* Update troubleshooting documentation for catalog errors and use of GitHub Secrets (1757677)'
```

## Root Cause
The issue occurs in the "Create Release Notes" step where Git commit messages that contain special characters are written to the GitHub environment variables file (`$GITHUB_ENV`). GitHub Actions has specific requirements for setting multi-line environment variables, and certain characters in commit messages can cause parsing issues.

## Solution
Fix the changelog generation step by properly handling multi-line environment variables in GitHub Actions:

1. First write the output to a temporary file
2. Use the GitHub Actions multi-line syntax for environment variables (with delimiter)

### Fixed Code:
```yaml
- name: Create Release Notes
  id: release_notes
  run: |
    # Get commits since last tag
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    # Create changelog file first
    if [[ -z "$LAST_TAG" ]]; then
      # First release - use all commits
      git log --pretty=format:'* %s (%h)' --no-merges > changelog.txt
    else
      # Get commits since last tag
      git log ${LAST_TAG}..HEAD --pretty=format:'* %s (%h)' --no-merges > changelog.txt
    fi
    
    # Use GitHub's proper multiline environment variable syntax
    {
      echo "CHANGELOG<<EOF"
      cat changelog.txt
      echo "EOF"
    } >> $GITHUB_ENV
```

Key changes:
1. Using single quotes in `--pretty=format:'* %s (%h)'` to avoid shell interpretation of special characters
2. Writing to a temp file first with `> changelog.txt`
3. Using GitHub's heredoc-style syntax for multi-line environment variables with `<<EOF` delimiter

## Implementation Instructions
1. Apply the above fix to the GitHub Actions workflow file
2. Remove any existing failed tags if needed
3. If the workflow file has already been updated but is still failing, check for hidden characters in commit messages or special character escaping

This approach handles special characters in commit messages, eliminating the format parsing error.
