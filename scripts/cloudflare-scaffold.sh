#!/bin/bash
# Single-command scaffold for the Cloudflare AI Playground
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Installing backend + tooling dependencies..."
npm install

echo "Installing frontend dependencies..."
(cd frontend && npm install)

echo "Starting development servers (Worker + Vite)..."
npm run dev:worker &
npm run dev:frontend

echo "Setup complete! Worker on http://localhost:8787, Frontend on http://localhost:5173"
