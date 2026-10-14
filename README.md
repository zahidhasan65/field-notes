Field Notes
Field Notes is a mobile app for field workers. It helps users manage
customers, their sites, and notes from site visits. The app saves
changes on the phone first and syncs them with the backend when a
connection is available.
Features
- Register and log in.
- Add, view, edit, and delete customers, sites, and field notes.
- Keep multiple sites under a customer and multiple notes under a
  site.
- Save changes offline and sync them later.
- Restore data from the server after local data is cleared or the app
  is reinstalled.
- Search notes by title, description, site, or customer.
- Filter notes by status or site.
- Add an optional photo to a field note.
- Get the current location when permission and location services are
  available.
- Set a default status for new notes. This setting is stored on the
  phone.
- View sync and connection notifications.
- Update profile details and change the app theme.
- Use Google sign-in after the required OAuth setup.
Technology
Mobile: Flutter, Dart, BLoC, SQLite, REST API
Backend: Java, Spring Boot, Spring Data JPA, PostgreSQL, JWT, Flyway
Development and deployment: Docker Compose for local development;
Render for the deployed backend.
How the app is organised
field-notes/
├── mobile/       # Flutter app
│   ├── lib/
│   │   ├── app/
│   │   ├── core/
│   │   ├── data/
│   │   ├── features/
│   │   ├── services/
│   │   └── widgets/
│   ├── assets/
│   └── pubspec.yaml
└── backend/      # Spring Boot REST API
    ├── src/
    ├── Dockerfile
    ├── docker-compose.yml
    └── pom.xml
Architecture
The Flutter screens send events to BLoC. Repositories coordinate access
to the local SQLite database and the REST API. The Spring Boot backend
handles API requests and stores server data in PostgreSQL.
Flutter UI → BLoC → Repositories → SQLite
                           └──────→ REST API → Spring Boot → PostgreSQL
Data model
- A user has their own customers and related records.
- A customer can have multiple sites.
- A site can have multiple field notes.
- A field note belongs to a site and can contain a title, description,
  location, date and time, status, and an optional photo.
The backend uses database relationships to retrieve site and customer
information for note searches, rather than storing duplicate site and
customer names in each note.
Offline work and sync
The app uses SQLite to keep local records. When a record is changed, the
app also records the operation in a sync queue. When the connection is
available, the sync process sends pending changes to the backend.
- Record IDs are UUIDs, so records created offline can keep the same
  ID when sent to the server.
- Customers are sent before sites and notes, so related records can be
  created in order.
- The app can sync after login, when connectivity returns, when the
  user refreshes, or when they choose Sync now. It also makes
  periodic sync attempts.
- Failed operations can be retried. Unsynced local changes are
  protected from being overwritten by pulled server data.
- GET /api/sync/changes is used to pull changes. Calling it without
  a since value returns a full snapshot for restore.
- Logging out keeps local data. The Clear Local Data option
  removes local records so they can be restored from the server after
  login.
Backend deployment
The backend is deployed on Render.
- API base URL: https://field-notes-e1zv.onrender.com/api
- Health endpoint:
  https://field-notes-e1zv.onrender.com/api/health
The mobile app uses this API URL by default. You can set API_BASE_URL
to use a local backend instead.
Run the mobile app
Install Flutter and set up an Android emulator or a connected device.
Then open a terminal in the mobile directory and run:
flutter pub get
flutter analyze
flutter run
Use the deployed backend
The deployed URL is the default. You can also set it explicitly:
flutter run --dart-define=API_BASE_URL=https://field-notes-e1zv.onrender.com/api
Use a local backend
Start the backend first. For an Android emulator, use:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
For a physical phone on the same Wi-Fi network, replace the address with
your computer's local IP:
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
Replace 192.168.1.10 with the actual IP address of your computer.
Local HTTP testing may require the platform settings in
mobile/PLATFORM_SETUP.md.
Run the backend locally
Requirements: Docker Desktop with Docker Compose.
Open a terminal in backend. Create a local environment file from the
example:
cp .env.example .env
Set the required values in .env, including the database password and
JWT secret. Do not commit .env or secrets to GitHub.
Start the services:
docker compose up --build
The backend is available at http://localhost:8080/api. Flyway runs the
database migrations when the backend starts. For an Android emulator,
the local API address is http://10.0.2.2:8080/api.
Authentication
The backend supports email/password registration and login using JWT.
Google sign-in needs Google Cloud OAuth configuration. Follow
[`mobile/GOOGLE_SETUP.md`](mobile/GOOGLE_SETUP.md), then run the app
with your Web client ID:
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<your-web-client-id>
Do not put a Google client secret in the Flutter app or commit
credentials to the repository.
Forgot password and email
The password reset flow currently uses a demo OTP. The OTP is shown in
the app instead of being sent by email.
SMTP/email delivery has not been configured for this project because
it is running on Render's free plan. The current flow uses the
development OTP returned by the backend. The OTP is six digits, is valid
for 10 minutes, and is invalidated after five incorrect attempts. A
supported email service can be configured later to send OTPs by email.
This is a demo flow and should not be treated as production email
verification.
Main API endpoints
  Method                  Endpoint                                   Purpose
  POST                  /api/auth/register                       Create an account
  POST                  /api/auth/login                          Log in
  POST                  /api/auth/forgot-password                Start password reset
  POST                  /api/auth/reset-password                 Reset password with OTP
  POST                  /api/auth/google                         Google sign-in
  GET, POST           /api/customers                           List or create
                                                                     customers
  GET, PUT, DELETE  /api/customers/{id}                      Manage a customer
  GET, POST           /api/customers/{customerId}/sites        List or create sites
                                                                     for a customer
  GET, PUT, DELETE  /api/customers/{customerId}/sites/{id}   Manage a site
  GET, POST           /api/sites/{siteId}/field-notes          List or create notes
                                                                     for a site
  GET, PUT, DELETE  /api/sites/{siteId}/field-notes/{id}     Manage a field note
  GET                   /api/field-notes                         Search and filter notes
  GET                   /api/sync/changes                        Pull changes or restore
                                                                     data
  GET, PUT            /api/users/me                            View or update the
                                                                     profile
  POST                  /api/users/me/change-password            Change password
The backend also has endpoints for uploading, viewing, updating, and
deleting field-note photos.
Photos and location
The app includes services for selecting photos from the camera or
gallery, storing photos locally, and getting the current location when
permission is granted. Locations are stored as coordinates; the app does
not include a map SDK.
Check mobile/PLATFORM_SETUP.md for platform permission setup.
Tests
Run Flutter checks from the mobile directory:
flutter analyze
flutter test
Run backend tests from the backend directory using Maven or the
project's Docker setup. Only report a test as passing after running it
against the current code.
Current limitations
- Password reset uses a demo OTP; SMTP/email delivery is not
  configured.
- Google sign-in needs OAuth configuration.
- There is no integrated map SDK; locations are stored as coordinates.
- Confirm optional flows in the current build before presenting them
  as fully working.
Security
- Do not commit .env, passwords, JWT secrets, OAuth secrets, or
  signing keys.
- Keep deployment secrets in Render's environment settings.
- Use HTTPS for the deployed API.
- Make sure users can access only their own records.