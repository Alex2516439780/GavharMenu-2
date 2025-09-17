param(
  [Parameter(Mandatory=$true)][string]$Remote,
  [string]$Target = "/opt/gavhar"
)

$repo = "https://github.com/Alex2516439780/GavharMenu-2.git"

$script = @'
set -euo pipefail

if [ -z "${APP_DIR:-}" ]; then
  echo "APP_DIR not set" >&2; exit 1
fi
if [ -z "${REPO_URL:-}" ]; then
  echo "REPO_URL not set" >&2; exit 1
fi

if [ ! -d "$APP_DIR" ]; then
  sudo mkdir -p "$APP_DIR"
  sudo chown -R "$USER":"$USER" "$APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR"

git pull --ff-only || true

if command -v npm >/dev/null 2>&1; then
  npm ci
  npm run build
  npm run images:generate || true
  npm run update-version || true
fi

if command -v pm2 >/dev/null 2>&1; then
  pm2 start ecosystem.config.js || true
  pm2 restart gavhar || true
  pm2 save || true
fi
'@

$envs = "REPO_URL='$repo' APP_DIR='$Target'"
$script | ssh -o StrictHostKeyChecking=no $Remote "$envs bash -s"





