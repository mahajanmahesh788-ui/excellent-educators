# ExcellentEducators Web

Flutter Web client for ExcellentEducators. Android/iOS platforms are enabled for later reuse.

## Run locally

Start the API first (default `http://127.0.0.1:8000`):

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd excellent-educators-web
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Use a different port if needed, e.g. `--dart-define=API_BASE_URL=http://127.0.0.1:8001`.

## Screens by role

After login, routing depends on role:

### Admin
- Dashboard, Students, Teachers, Batches
- Aptitude assessments (CRUD, activate, attempts)
- Admin requests inbox
- Student detail: aptitude results, Master Teacher ratings (read-only)

### Common Teacher
- My batches → batch students → **Batch assessments** (scoring)
- Student results: aptitude + Master Teacher ratings (read-only)
- Profile, Request admin

### Master Teacher
- My students with **month** and **rated / not rated** filters
- Student detail: aptitude, add/edit monthly ratings, trend graph, history
- Profile, Request admin

### Student
- Dashboard (aptitude assessment when pending)
- After submit: confirmation only — **dimension charts are not shown to students**
- Monthly feedback, profile, request admin

## Account

- **Change password**: **Password** button in the top app bar (all signed-in roles)
- **Forgot password**: link on the login page

## Tests

```bash
flutter test
```

Covers widgets, date formatting, master teacher student filters, and form validation.
