# ExcellentEducators

Monorepo with two apps:

- [`excellent-educators-api`](excellent-educators-api/) — Laravel REST API (`/api/v1`) and PostgreSQL
- [`excellent-educators-web`](excellent-educators-web/) — Flutter Web client

The Flutter app talks to the API only — never to the database directly.

## Quick start

**1. API**

```bash
cd excellent-educators-api
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

**2. Web**

```bash
cd excellent-educators-web
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Current features

| Area | What works |
|---|---|
| **Auth** | Login, logout, forgot/reset password, in-app change password |
| **Admin** | Dashboard, students, teachers, batches, aptitude assessments, requests, read-only ratings |
| **Common Teacher** | Batches, batch scoring assessments, student aptitude results, read-only ratings |
| **Master Teacher** | My students (month + rated filters), monthly ratings, student detail |
| **Student** | Dashboard, aptitude assessment submit, monthly feedback view, profile, requests |

## Product notes

- **Student aptitude results** are visible to teachers and admin only — not to the student after submission.
- **Monthly ratings** are one per student per month (Master Teacher).
- **Student IDs** are generated server-side (`{CC}-APS-{YY}-{SEQ4}`).

See each repo README for API routes, seeded accounts, and run details.
