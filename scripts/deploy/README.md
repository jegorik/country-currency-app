# Scripts - Deployment

This directory contains scripts used for deploying the Country Currency App to different environments. These deployment scripts were consolidated and relocated here as part of the project cleanup to improve organization.

## Files

- `deploy_windows.ps1` - Windows-specific deployment script
- `unified_deploy.ps1` - Unified Windows deployment script that works across environments
- `unified_deploy.sh` - Unified Linux/macOS deployment script that works across environments

## Usage

### Windows

```powershell
# Using from the scripts/deploy directory
./unified_deploy.ps1 -Environment dev

# Using from project root
scripts/deploy/unified_deploy.ps1 -Environment dev
```

### Linux/macOS

```bash
# Using from the scripts/deploy directory
bash unified_deploy.sh -e dev

# Using from project root
bash scripts/deploy/unified_deploy.sh -e dev
```
