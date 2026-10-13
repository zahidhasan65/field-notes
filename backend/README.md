# Field Notes backend (Spring Boot + PostgreSQL)

## Run
```bash
cp .env.example .env        # fill passwords; JWT_SECRET = output of:  openssl rand -base64 48
docker compose up --build   # Flyway applies V1..V7 automatically
```
API: `http://localhost:8080/api`   (Android emulator: `http://10.0.2.2:8080/api`)
Photos are stored in the `field_notes_uploads` volume (`UPLOAD_DIR=/app/uploads`).

## What changed in this version
* **V6 migration**: customers get contact_person / email / phone / address; sites get latitude / longitude;
  field_notes get title, description, status, note_datetime, latitude, longitude, photo_path
  (old `note` text is migrated into title + description, then the column is dropped).
* **Client ids**: `POST` bodies accept an optional `id` (UUID). Retrying the same create returns the existing row (idempotent),
  another user's id -> 409. This is what makes offline create + sync safe.
* **Cascade soft delete**: deleting a customer deletes its sites + notes; deleting a site deletes its notes.
* **Sync endpoint** `GET /api/sync/changes[?since=ISO-8601]`: customers, sites and notes changed after `since`
  (soft-deleted rows included, `deletedAt != null` = tombstone). Without `since` = full snapshot (restore).
  Store `serverTime` and send it as the next `since`.
* **Search** `GET /api/field-notes?search=&status=&siteId=`: JPA Specification with JOINs (note -> site -> customer),
  returns site and customer names without duplicating them in the tables.
* **Photo**: `POST|PUT /api/field-notes/{id}/photo` (multipart field `file`, jpeg/png/webp/heic, max 10 MB),
  `GET` returns the image, `DELETE` removes it. Note responses contain `photoUrl`.
* Services are `@Transactional`; invalid JSON -> 400, oversize upload -> 413.

## Forgot password (demo OTP) and Google login
* `POST /api/auth/forgot-password` `{ "email" }` -> creates a 6 digit OTP (BCrypt hashed in `users`, valid 10 min, V7 migration).
  While `DEV_OTP_ENABLED=true` (default) the response contains `devOtp` and an unknown email returns 404, so the app can
  show the OTP in a snackbar. In production set `DEV_OTP_ENABLED=false` and send the OTP by e-mail (the response then never contains it).
* `POST /api/auth/reset-password` `{ "email", "otp", "newPassword" }` -> 5 wrong attempts invalidate the OTP.
* `POST /api/auth/google` `{ "idToken" }` -> token is verified with Google (audience must equal `GOOGLE_CLIENT_ID`,
  e-mail must be verified), user is found or created, normal JWT returned. Setup: `mobile/GOOGLE_SETUP.md`.

## Endpoints
| Method | Path | Notes |
|---|---|---|
| POST | /api/auth/register, /api/auth/login | JWT (password min 8 chars) |
| POST | /api/auth/forgot-password, /api/auth/reset-password | OTP flow (demo mode) |
| POST | /api/auth/google | Google ID token -> JWT |
| GET/POST | /api/customers | |
| GET/PUT/DELETE | /api/customers/{id} | |
| GET/POST | /api/customers/{customerId}/sites | |
| GET/PUT/DELETE | /api/customers/{customerId}/sites/{id} | PUT may send `customerId` to move the site |
| GET/POST | /api/sites/{siteId}/field-notes | |
| GET/PUT/DELETE | /api/sites/{siteId}/field-notes/{id} | PUT may send `siteId` to move the note |
| GET | /api/field-notes | search / filter with JOINs |
| POST/PUT/GET/DELETE | /api/field-notes/{id}/photo | |
| GET | /api/sync/changes | pull / restore |

Conflict policy: last write wins on the server; the app never overwrites a row that still has unsynced local changes.
