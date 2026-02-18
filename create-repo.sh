#!/bin/bash
# Script to create the axiomcore repository using GitHub CLI

set -e

echo "Creating axiomcore repository..."
echo "Organization: TechFusion-Quantum-Global-Platform"
echo "Repository: axiomcore"
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
gh repo create TechFusion-Quantum-Global-Platform/axiomcore \
  --private \
  --description "AxiomCore MVP — backend, frontend, AI orchestration" \
  --confirm

echo ""
echo "Repository created successfully!"
echo "Clone it with:"
echo "  git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git"
