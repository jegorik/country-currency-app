# Scripts - Deployment

This directory contains scripts used for deploying the Country Currency App to different environments.

## Files

- `deploy_windows.ps1` - Windows-specific deployment script
- `unified_deploy.ps1` - Unified Windows deployment script that works across environments
- `unified_deploy.sh` - Unified Linux/macOS deployment script that works across environments

## Usage

### Windows

```powershell
./deploy_windows.ps1 -environment dev
```

### Linux/macOS

```bash
./unified_deploy.sh -e dev
```
