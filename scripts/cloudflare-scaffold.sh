#!/bin/bash
# Single-command scaffold for the Cloudflare AI Playground

echo "Cloning AxiomCore + Cloudflare Scaffold..."
git clone https://github.com/TechFusion-Quantum-Global-Platform/axiomcore-cloudflare.git
cd axiomcore-cloudflare || exit 1

echo "Installing backend dependencies..."
npm install

echo "Installing frontend dependencies..."
cd frontend && npm install && cd ..

echo "Starting development servers..."
# Backend Worker Dev
npm run dev:worker &
# Frontend React Dev
npm run dev:frontend

echo "Setup complete! Open http://localhost:5173"
