#!/bin/bash
# Auto-detect OS and run appropriate deployment script

# Detect OS
OS_TYPE="unknown"
case "$(uname -s)" in
    Linux*)     OS_TYPE="linux";;
    Darwin*)    OS_TYPE="macos";;
    CYGWIN*)    OS_TYPE="windows";;
    MINGW*)     OS_TYPE="windows";;
    MSYS*)      OS_TYPE="windows";;
    Windows*)   OS_TYPE="windows";;
    *)          OS_TYPE="unknown";;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run appropriate deployment script
if [ "$OS_TYPE" = "windows" ]; then
    echo "Windows detected, running PowerShell deployment script..."
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/deploy_windows.ps1"
elif [ "$OS_TYPE" = "linux" ] || [ "$OS_TYPE" = "macos" ]; then
    echo "Unix-like system detected (Linux/macOS), running Bash deployment script..."
    bash "$SCRIPT_DIR/deploy_linux.sh"
else
    echo "Unknown operating system. Please run one of the following scripts manually:"
    echo "- Windows: scripts/deploy_windows.ps1"
    echo "- Linux/macOS: scripts/deploy_linux.sh"
    exit 1
fi
