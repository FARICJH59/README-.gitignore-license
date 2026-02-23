#!/bin/bash
# Script to create the axiomcore repository using GitHub CLI

set -e

echo "Creating Axiomcore-SYSTEM repository..."
echo "Owner: FARIJCH59"
echo "Repository: Axiomcore-SYSTEM"
echo "Visibility: private"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: GitHub CLI is not authenticated."
    echo "Please run: gh auth login"
    exit 1
fi

# Create the repository
gh repo create FARIJCH59/Axiomcore-SYSTEM \
  --private \
  --description "AxiomCore MVP — backend, frontend, AI orchestration" \
  --confirm

echo ""
echo "Repository created successfully!"
echo "Clone it with:"
echo "  git clone https://github.com/FARIJCH59/Axiomcore-SYSTEM.git"
