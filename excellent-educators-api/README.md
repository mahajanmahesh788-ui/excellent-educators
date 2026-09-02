# ExcellentEducators API

Laravel REST API for ExcellentEducators (`/api/v1`).

## Local setup

PostgreSQL 16, database `excellent_educators`.

```bash
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

Use `migrate:fresh --seed` only when you want to wipe local data.

## Seeded local admins

| Account | Email | Password | Role |
|---|---|---|---|
| Admin 1 | admin1@excellenteducators.test | ChangeMeAdmin1! | super_admin |
| Admin 2 | admin2@excellenteducators.test | ChangeMeAdmin2! | operational_admin |
| Admin 3 | admin3@excellenteducators.test | ChangeMeAdmin3! | operational_admin |

Change these passwords after first login.

## Auth (`Authorization: Bearer {token}`, 8h TTL)

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/me`
- `PUT /api/v1/auth/password` — invalidates all tokens; client must log in again
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`

## Admin (`super_admin` or `operational_admin`)

**Academic**
- `GET /api/v1/admin/dashboard`
- `GET /api/v1/admin/career-compass-levels`
- `GET|POST /api/v1/admin/students`, `GET|PUT /api/v1/admin/students/{student}`
- `PUT /api/v1/admin/students/{student}/mentor`, `DELETE .../mentor`
- `GET|POST /api/v1/admin/teachers`, `GET|PUT /api/v1/admin/teachers/{teacher}`
- `GET|POST /api/v1/admin/batches`, `GET|PUT /api/v1/admin/batches/{batch}`
- `GET|POST /api/v1/admin/batches/{batch}/students`, `DELETE .../students/{student}`
- `POST|DELETE /api/v1/admin/batches/{batch}/teacher`

**Aptitude assessments**
- `GET|POST /api/v1/admin/assessments`, `GET|PUT|DELETE /api/v1/admin/assessments/{id}`
- `POST .../activate`, `POST .../deactivate`, `GET .../attempts`
- Question/option CRUD under each assessment

**Feedback & results**
- `GET /api/v1/admin/students/{student}/results`
- `GET /api/v1/admin/students/{student}/feedback`, `.../feedback/summary`

**Requests**
- `GET /api/v1/admin/requests`, `GET /api/v1/admin/requests/{id}`, `POST .../resolve`

## Common Teacher

- `GET /api/v1/teacher/profile`
- `GET /api/v1/teacher/batches`, `GET .../batches/{batch}/students`
- `GET|POST /api/v1/teacher/batches/{batch}/assessments`
- `GET|PUT .../assessments/{assessment}`, `GET|PUT .../scores`
- `GET /api/v1/teacher/students/{student}`, `.../results`, `.../feedback`, `.../feedback/summary`
- `GET|POST /api/v1/teacher/requests`

## Master Teacher

- `GET /api/v1/master-teacher/students?year=&month=&rated=` — filters: `rated=1` (rated), `rated=0` (not rated)
- `GET /api/v1/master-teacher/students/{student}`
- `GET /api/v1/master-teacher/feedback-catalog`
- `GET /api/v1/master-teacher/students/{student}/results`
- `GET|POST /api/v1/master-teacher/students/{student}/feedback`
- `GET|PUT|DELETE /api/v1/master-teacher/students/{student}/feedback/{feedback}` — master teacher edit/delete only during the rating month and only their own submissions
- `GET|POST|PUT|DELETE /api/v1/admin/students/{student}/feedback[/{feedback}]` — admin override anytime
- `GET /api/v1/admin/feedback-catalog`

## Student

- `GET /api/v1/student/profile`
- `GET /api/v1/student/assessment`, `POST .../assessment/{id}/submit`
- `GET /api/v1/student/results` — **403 by design** (results for teachers/admin only)
- `GET /api/v1/student/feedback`, `GET .../feedback/summary`
- `GET|POST /api/v1/student/requests`

## Rules

- Student IDs (`student_code`) are generated as `{CC}-APS-{YY}-{SEQ4}` — not client-supplied.
- Max **40 active students** per batch.
- **One monthly rating** per student per calendar month.
- Master Teachers can edit or delete their own rating only during that rating month; after reassignment, neither old nor new master can change an existing rating (admin can).
- Common Teachers → batches; Master Teachers → students. Replacing assignments keeps history.

## Tests

```bash
php artisan test
```

Feature tests cover auth, academic core, assessments, aptitude flow, monthly feedback, and admin requests.
