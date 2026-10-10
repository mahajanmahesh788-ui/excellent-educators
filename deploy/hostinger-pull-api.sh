#!/usr/bin/env bash
# Run on Hostinger VPS as root from any directory.
# Deploys API from git + refreshes caches. Flutter web is built separately.
set -euo pipefail

APP_ROOT=/var/www/excellent-educators
API_ROOT="$APP_ROOT/excellent-educators-api"

cd "$APP_ROOT"

echo "=== 1) Clean macOS AppleDouble junk ==="
find . -name '._*' -type f -delete
find . -name '.DS_Store' -type f -delete

echo "=== 2) Sync git (discard local junk, keep .env) ==="
# Keep production secrets
if [ ! -f "$API_ROOT/.env" ]; then
  echo "ERROR: missing $API_ROOT/.env — stop and restore it."
  exit 1
fi

git fetch origin
git status -sb
# Reset tracked files to origin/main; keep untracked .env and vendor
git checkout main
git reset --hard origin/main
git clean -fd -e excellent-educators-api/.env -e excellent-educators-api/vendor -e excellent-educators-api/storage -e app-web -e excellent-educators-web

echo "=== HEAD after sync ==="
git log -3 --oneline

echo "=== 3) Production env guard ==="
cd "$API_ROOT"
if grep -qE '^APP_DEBUG\s*=\s*true' .env; then
  echo "ERROR: APP_DEBUG=true in $API_ROOT/.env"
  echo "Set APP_DEBUG=false before deploying to production."
  exit 1
fi
if ! grep -qE '^APP_ENV\s*=\s*production' .env; then
  echo "ERROR: APP_ENV must be production in $API_ROOT/.env"
  exit 1
fi
if grep -qE '^CORS_ALLOWED_ORIGINS\s*=\s*\*' .env || ! grep -qE '^CORS_ALLOWED_ORIGINS\s*=' .env; then
  echo "ERROR: Set CORS_ALLOWED_ORIGINS to your real frontend domain(s), e.g."
  echo "  CORS_ALLOWED_ORIGINS=https://excellenteducators.in,https://www.excellenteducators.in"
  echo "Do not use * in production."
  exit 1
fi
if ! grep -qE '^FRONTEND_URL\s*=\s*https?://' .env; then
  echo "ERROR: FRONTEND_URL must be set to your public site URL."
  exit 1
fi
if grep -qE '^CACHE_STORE\s*=\s*database' .env; then
  echo "WARN: CACHE_STORE=database — prefer CACHE_STORE=file (or redis) on production for fewer DB hits."
fi

echo "=== 4) Composer (prod) ==="
composer install --no-dev --optimize-autoloader --no-interaction

echo "=== 5) Permissions ==="
chown -R www-data:www-data storage bootstrap/cache
chmod -R ug+rwx storage bootstrap/cache

echo "=== 6) Migrate + bootstrap seed ==="
php artisan migrate --force
php artisan db:seed --force
php artisan storage:link || true

echo "=== 7) Optimize ==="
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

echo "=== 8) Health ==="
php artisan about | head -30
curl -sS -o /dev/null -w "API HTTP %{http_code}\n" https://api.excellenteducators.in/ || true

echo "=== API deploy done ==="
echo "Next: build Flutter web on your Mac and upload to $APP_ROOT/app-web"
echo "  flutter build web --release --dart-define=API_BASE_URL=https://api.excellenteducators.in"
echo "Nginx: apply gzip + asset caching from deploy/nginx-app-web.conf.example"
echo "Prod .env tip: CACHE_STORE=file"
