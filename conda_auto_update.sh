#!/bin/bash
ERROR_LOG="setup_error.log"
REQUIREMENTS_FILE="/c/Users/Ilai/Desktop/projects/DS-101-Final/requirements.txt"
conda install "$@" -y 2>&1 | tee -a "$ERROR_LOG"
conda list --export | grep -v "^#" > "$REQUIREMENTS_FILE"
echo "✅ Updated $REQUIREMENTS_FILE after installing: $@"
