#!/bin/bash

set -e  # Exit on error

# Debugging: Print all errors with full output
ERROR_LOG="setup_error.log"
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND" | tee -a "$ERROR_LOG"; exit 1' ERR

# Default values (can be overridden)
ENV_NAME="Houri"  # Change this to your desired Conda environment name
PYTHON_VERSION="3.12.2"  # Default Python version
REQUIREMENTS_FILE="$(pwd)/requirements.txt"  # Absolute path to avoid issues
CUSTOM_CHANNELS=("conda-forge")  # Add custom Conda channels here

# Allow user to override Python version via command-line argument
if [ -n "$1" ]; then
    PYTHON_VERSION="$1"
fi

echo "🔍 Checking if jq is installed..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "⚠️ jq not found! Installing..."

    # Detect OS and install jq
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "🟢 Detected Linux. Installing jq..."
        sudo apt update && sudo apt install -y jq || sudo yum install -y jq || sudo dnf install -y jq

    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍏 Detected macOS. Installing jq..."
        brew install jq

    elif [[ "$OS" == "Windows_NT" ]]; then
        echo "🪟 Detected Windows. Installing jq..."
        curl -L -o jq.exe https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe
        mv jq.exe /usr/local/bin/jq || mv jq.exe /c/Windows/system32/jq.exe

    else
        echo "❌ Unsupported OS. Please install jq manually."
        exit 1
    fi
else
    echo "✅ jq is already installed!"
fi

# Set up Git filter
echo "🔧 Setting up Git filter for Jupyter Notebooks..."
git config --global filter.clear_notebook_outputs.clean "jq '(.cells[] | select(.cell_type==\"code\") | .outputs) = []' | jq 'del(.metadata.execution_count)'"

# Create .gitattributes if missing
if [ ! -f .gitattributes ]; then
    echo "*.ipynb filter=clear_notebook_outputs" > .gitattributes
    git add .gitattributes
fi

echo "✅ Git filter setup complete!"

# -----------------------------
# Conda Environment Setup
# -----------------------------

echo "🐍 Checking Conda installation..."
if ! command -v conda &> /dev/null; then
    echo "❌ Conda is not installed. Please install Anaconda or Miniconda first."
    exit 1
fi

echo "🔍 Checking if Conda environment '$ENV_NAME' exists..."
if conda info --envs | grep -q "^$ENV_NAME "; then
    echo "✅ Conda environment '$ENV_NAME' already exists."
else
    echo "🚀 Creating new Conda environment '$ENV_NAME' with Python $PYTHON_VERSION..."
    conda create --name "$ENV_NAME" python="$PYTHON_VERSION" -y | tee -a "$ERROR_LOG"
fi

# Activate environment persistently
echo "🔄 Persistently activating Conda environment '$ENV_NAME'..."
eval "$(conda shell.bash hook)"  # Ensure Conda works in scripts
conda activate "$ENV_NAME"

if [ "$(conda info --envs | grep '*' | awk '{print $1}')" != "$ENV_NAME" ]; then
    echo "❌ Failed to activate Conda environment '$ENV_NAME'. Exiting..." | tee -a "$ERROR_LOG"
    exit 1
fi
echo "✅ Conda environment '$ENV_NAME' is active."

# -----------------------------
# Installing Dependencies
# -----------------------------

if [ -f "$REQUIREMENTS_FILE" ]; then
    echo "📦 Installing dependencies from $REQUIREMENTS_FILE..."
    
    # Check if file is empty
    if [ ! -s "$REQUIREMENTS_FILE" ]; then
        echo "⚠️ $REQUIREMENTS_FILE is empty. Skipping Conda package installation."
    else
        # Use custom channels
        for CHANNEL in "${CUSTOM_CHANNELS[@]}"; do
            conda config --add channels "$CHANNEL" || {
                echo "❌ Failed to add custom channel '$CHANNEL'. Exiting..." | tee -a "$ERROR_LOG"
                exit 1
            }
        done

        conda install --yes --file "$REQUIREMENTS_FILE" 2>&1 | tee -a "$ERROR_LOG" || {
            echo "❌ Failed to install packages from $REQUIREMENTS_FILE. Check for typos or invalid package names." | tee -a "$ERROR_LOG"
            exit 1
        }
    fi
else
    echo "⚠️ No $REQUIREMENTS_FILE found. Creating an empty one..."
    touch "$REQUIREMENTS_FILE"
fi

# -----------------------------
# Jupyter Notebook Kernel Setup
# -----------------------------

echo "📚 Setting up Jupyter Notebook kernel..."

# Ensure Jupyter is installed correctly
if ! conda list jupyter | grep -q jupyter; then
    echo "📦 Installing Jupyter..."
    conda install -y jupyter 2>&1 | tee -a "$ERROR_LOG"
fi

# Add Conda environment to Jupyter
echo "🔄 Adding '$ENV_NAME' as a Jupyter kernel..."
python -m ipykernel install --user --name "$ENV_NAME" --display-name "Python ($ENV_NAME)" 2>&1 | tee -a "$ERROR_LOG"

echo "✅ Jupyter kernel for '$ENV_NAME' is set up!"

# -----------------------------
# Final Verification
# -----------------------------

echo "🔍 Checking active Conda environment..."
conda info --envs | grep '*'

echo "🎉 Setup complete! You can now start working on your project."
echo "🚀 To activate the Conda environment, run: conda activate $ENV_NAME"
echo "⚡ Use 'conda-install package_name' instead of 'conda install' to auto-update requirements.txt!"
echo "📚 To use Jupyter with this environment, run: jupyter notebook"
