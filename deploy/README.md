# Deploy notes (Hostinger / VPS)

## API

Run `hostinger-pull-api.sh` on the server (keeps `.env`, migrates, caches config).

Production `.env` checklist:

- `APP_ENV=production`
- `APP_DEBUG=false`
- `CORS_ALLOWED_ORIGINS=` your real frontend origin(s) (no `*`)
- `FRONTEND_URL=` public site URL
- `CACHE_STORE=file` (or `redis`) — avoid `database` for request-path caching

## Flutter web

```bash
cd excellent-educators-web
flutter build web --release --dart-define=API_BASE_URL=https://api.excellenteducators.in
# upload build/web/* → /var/www/excellent-educators/app-web
```

`web/index.html` includes a branded boot splash so users are not stuck on a blank white page while the large Flutter bundle loads.

## Nginx (first-load performance)

Apply `nginx-app-web.conf.example` ideas to your site config:

1. **Gzip** (and Brotli if available) for `.js` / `.wasm`
2. **Long cache** for static assets
3. **No long cache** for `index.html`, `version.json`, `flutter_service_worker.js`

Then:

```bash
sudo nginx -t && sudo systemctl reload nginx
```
