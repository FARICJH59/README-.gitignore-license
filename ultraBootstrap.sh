#!/bin/bash
# Ultra Bootstrap Script for AxiomCore Autonomous AI Company Engine

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git}"
TARGET_DIR="${TARGET_DIR:-$HOME/Projects/axiomcore}"
RUN_TESTS=false
START_STACK=false
ALLOW_DIRTY=false
VENV_DIR="${VENV_DIR:-}"

usage() {
  cat <<'EOF'
Ultra Bootstrap for AxiomCore

Options:
  --repo-url <url>     Git URL to clone (default: https://github.com/TechFusion-Quantum-Global-Platform/axiomcore.git)
  --target-dir <path>  Destination directory (default: $HOME/Projects/axiomcore)
  --force              Skip clean working tree checks when pulling existing clone
  --run-tests          Run npm test after installing dependencies
  --start-stack        Launch backend + frontend via PowerShell (pwsh) if available
  -h, --help           Show this help message

Environment overrides:
  REPO_URL, TARGET_DIR, BRAIN_HOME, VENV_DIR
EOF
}

print_manual_start() {
  echo "   python3 server.py &"
  echo "   (cd frontend && npm run dev)"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-url)
      REPO_URL="$2"
      shift 2
      ;;
    --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    --run-tests)
      RUN_TESTS=true
      shift
      ;;
    --start-stack)
      START_STACK=true
      shift
      ;;
    --force)
      ALLOW_DIRTY=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Missing required command: $1. Bootstrap aborted."
    exit 1
  fi
}

echo "🚀 Starting AxiomCore Ultra Bootstrap"

echo "🔎 Checking prerequisites..."
require_cmd git
require_cmd python3
require_cmd npm

echo "📥 Setting up AxiomCore repository..."
mkdir -p "$(dirname "$TARGET_DIR")"
if [[ -d "$TARGET_DIR/.git" ]]; then
  if [[ "$ALLOW_DIRTY" = false ]] && [[ -n "$(git -C "$TARGET_DIR" status --porcelain)" ]]; then
    echo "❌ Local changes detected in $TARGET_DIR. Please commit or stash them before updating."
    exit 1
  fi
  if ! git -C "$TARGET_DIR" pull --ff-only; then
    echo "❌ Git pull failed (non-fast-forward divergence or connectivity/auth issues)."
    echo "   Resolve divergence (rebase or merge upstream), or check network/auth, then retry in $TARGET_DIR."
    exit 1
  fi
else
  git clone "$REPO_URL" "$TARGET_DIR"
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
cd "$TARGET_DIR"

BRAIN_HOME="${BRAIN_HOME:-$TARGET_DIR}"
VENV_DIR="${VENV_DIR:-$TARGET_DIR/.venv}"

echo "🐍 Installing Python dependencies..."
if [[ -f requirements.txt ]]; then
  if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
  fi
  # shellcheck disable=SC1090
  source "$VENV_DIR/bin/activate"
  python3 -m pip install --upgrade pip
  python3 -m pip install -r requirements.txt
else
  echo "ℹ️ requirements.txt not found, skipping Python deps."
fi

echo "📦 Installing Node.js dependencies..."
npm install
if [[ -d frontend ]]; then
  npm --prefix frontend install
fi

if [[ -f brain-knowledge.sample.json ]]; then
  if [[ "$BRAIN_HOME" != "$TARGET_DIR" ]]; then
    mkdir -p "$BRAIN_HOME"
  fi
  if [[ ! -f "$BRAIN_HOME/brain-knowledge.json" ]]; then
    cp brain-knowledge.sample.json "$BRAIN_HOME/brain-knowledge.json"
    echo "🧠 Seeded $BRAIN_HOME/brain-knowledge.json from sample."
  else
    echo "🧠 Existing brain-knowledge.json detected at $BRAIN_HOME; leaving untouched."
  fi
fi

if [[ "$RUN_TESTS" = true ]]; then
  echo "🧪 Running npm test..."
  npm test
fi

if [[ "$START_STACK" = true ]]; then
  if [[ -f start-all.ps1 ]] && command -v pwsh >/dev/null 2>&1; then
    echo "▶️ Launching stack via PowerShell..."
    pwsh -NoLogo -NoProfile -File start-all.ps1
  else
    if [[ ! -f start-all.ps1 ]]; then
      echo "⚠️ start-all.ps1 not found in $(pwd);"
    fi
    if ! command -v pwsh >/dev/null 2>&1; then
      echo "⚠️ PowerShell (pwsh) not found;"
    fi
    echo "   Start services manually:"
    print_manual_start
  fi
else
  echo "✅ Bootstrap complete. Next steps:"
  echo "   cd \"$TARGET_DIR\""
  if command -v pwsh >/dev/null 2>&1; then
    echo "   pwsh -NoLogo -NoProfile -File start-all.ps1    # launch backend + frontend"
  else
    echo "   (install PowerShell Core for start-all.ps1, or run services manually)"
  fi
  print_manual_start
fi
