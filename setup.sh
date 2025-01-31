#!/bin/bash

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

echo "🎉 Setup complete! Notebook outputs will be cleared before commit."
