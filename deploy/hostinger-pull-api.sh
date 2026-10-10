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

echo "=== 3) Composer (prod) ==="
cd "$API_ROOT"
composer install --no-dev --optimize-autoloader --no-interaction

echo "=== 4) Permissions ==="
chown -R www-data:www-data storage bootstrap/cache
chmod -R ug+rwx storage bootstrap/cache

echo "=== 5) Migrate + bootstrap seed ==="
php artisan migrate --force
php artisan db:seed --force
php artisan storage:link || true

echo "=== 6) Optimize ==="
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

echo "=== 7) Health ==="
php artisan about | head -30
curl -sS -o /dev/null -w "API HTTP %{http_code}\n" https://api.excellenteducators.in/ || true

echo "=== API deploy done ==="
echo "Next: build Flutter web on your Mac and upload to $APP_ROOT/app-web"
echo "  flutter build web --release --dart-define=API_BASE_URL=https://api.excellenteducators.in"
