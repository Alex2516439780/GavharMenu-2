param(
  [Parameter(Mandatory=$true)][string]$Remote,
  [string]$Target = "/opt/gavhar"
)

$repo = "https://github.com/Alex2516439780/GavharMenu.git"

$script = @'
set -euo pipefail
REPO_URL="$repo"
APP_DIR="$Target"

if [ ! -d "$APP_DIR" ]; then
  sudo mkdir -p "$APP_DIR"
  sudo chown -R "$USER":"$USER" "$APP_DIR"
  git clone "$repo" "$Target"
fi
cd "$Target"

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

ssh -o StrictHostKeyChecking=no $Remote bash -s << 'EOS'
$script
EOS





