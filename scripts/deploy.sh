#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy.sh <ssh_user@host> </path/to/app>
# Example: ./scripts/deploy.sh ubuntu@1.2.3.4 /opt/gavhar

REMOTE=${1:-}
TARGET=${2:-/opt/gavhar}

if [[ -z "$REMOTE" ]]; then
  echo "Usage: $0 <ssh_user@host> </path/to/app>" >&2
  exit 1
fi

ssh -o StrictHostKeyChecking=no "$REMOTE" bash -s <<'EOS'
set -euo pipefail
REPO_URL="https://github.com/Alex2516439780/GavharMenu-2.git"
APP_DIR="${1:-/opt/gavhar}"

if [[ ! -d "$APP_DIR" ]]; then
  sudo mkdir -p "$APP_DIR"
  sudo chown -R "$USER":"$USER" "$APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

git pull --ff-only || true

# Install deps and build
if command -v npm >/dev/null 2>&1; then
  npm ci
  npm run build
  npm run images:generate || true
  npm run update-version || true
fi

# PM2 restart if present
if command -v pm2 >/dev/null 2>&1; then
  pm2 start ecosystem.config.js || true
  pm2 restart gavhar || true
  pm2 save || true
fi
EOS





