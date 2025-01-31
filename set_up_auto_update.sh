#!/bin/bash

set -e  # Exit on error

# Define the requirements file
REQUIREMENTS_FILE="$(pwd)/requirements.txt"

# Function to update requirements.txt
update_requirements() {
    if command -v conda &> /dev/null; then
        conda list --export | grep -v "^#" > "$REQUIREMENTS_FILE"
    fi
    if command -v pip &> /dev/null; then
        pip freeze > "$REQUIREMENTS_FILE"
    fi
    echo "✅ requirements.txt updated!"
}

# Detect OS and choose the correct shell config file
if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* || "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # For Linux, macOS, and Windows (Git Bash, WSL, Cygwin)
    SHELL_CONFIG="$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && SHELL_CONFIG="$HOME/.zshrc"

    # Append functions to shell configuration if not already added
    if ! grep -q "update_requirements" "$SHELL_CONFIG"; then
        cat << 'EOF' >> "$SHELL_CONFIG"

# Auto-update requirements.txt for conda and pip
update_requirements() {
    if command -v conda &> /dev/null; then
        conda list --export | grep -v "^#" > "$(pwd)/requirements.txt"
    fi
    if command -v pip &> /dev/null; then
        pip freeze > "$(pwd)/requirements.txt"
    fi
    echo "✅ requirements.txt updated!"
}

conda() {
    if [[ "$1" == "install" || "$1" == "uninstall" || "$1" == "remove" ]]; then
        command conda "$@" -y  # Run the original command
        update_requirements
    else
        command conda "$@"
    fi
}

pip() {
    if [[ "$1" == "install" || "$1" == "uninstall" || "$1" == "remove" ]]; then
        command pip "$@"
        update_requirements
    else
        command pip "$@"
    fi
}
EOF
    fi

    # ✅ **Apply changes immediately**
    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc"
    fi
    if [[ -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc"
    fi

    echo "✅ Auto-update enabled for conda and pip in $SHELL_CONFIG"

elif [[ "$OS" == "Windows_NT" ]]; then
    # Windows PowerShell
    POWERSHELL_PROFILE="$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"

    # Create profile if it doesn’t exist
    if [[ ! -f "$POWERSHELL_PROFILE" ]]; then
        New-Item -ItemType File -Path "$POWERSHELL_PROFILE" -Force
    fi

    # Append functions to PowerShell profile if not already added
    if ! grep -q "Update-Requirements" "$POWERSHELL_PROFILE"; then
        cat <<EOF >> "$POWERSHELL_PROFILE"
function Update-Requirements {
    if (Get-Command conda -ErrorAction SilentlyContinue) {
        conda list --export | Select-String -Pattern '^[^#]' | Out-File -Encoding utf8 "$(Get-Location)\requirements.txt"
    }
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        pip freeze | Out-File -Encoding utf8 "$(Get-Location)\requirements.txt"
    }
    Write-Host "✅ requirements.txt updated!"
}

function Conda {
    param([string[]]`$args)
    if (`$args[0] -eq "install" -or `$args[0] -eq "uninstall" -or `$args[0] -eq "remove") {
        & conda @args
        Update-Requirements
    } else {
        & conda @args
    }
}

function Pip {
    param([string[]]`$args)
    if (`$args[0] -eq "install" -or `$args[0] -eq "uninstall" -or `$args[0] -eq "remove") {
        & pip @args
        Update-Requirements
    } else {
        & pip @args
    }
}

Set-Alias conda Conda
Set-Alias pip Pip

Write-Host "✅ Normal 'conda install/uninstall' and 'pip install/uninstall' will now auto-update requirements.txt!"
EOF
    fi

    # ✅ **Apply PowerShell changes immediately**
    powershell.exe -Command ". $POWERSHELL_PROFILE"

    echo "✅ Auto-update enabled for Windows PowerShell"
else
    echo "❌ Unsupported OS. Please set up manually."
    exit 1
fi

echo "🎉 Setup complete! 'conda install/uninstall' and 'pip install/uninstall' will now auto-update requirements.txt!"
