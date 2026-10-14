# Google Sign-In Setup

Follow these steps to enable **Continue with Google** in Field Notes. You only need to do this setup once.

When a user signs in, the app sends a Google ID token to `POST /api/auth/google`. The backend checks the token with Google and returns the app's usual JWT. Keep your OAuth details in your own Google Cloud project.

## 1. Create OAuth clients

1. Open the [Google Cloud Console](https://console.cloud.google.com/) and create a project or select an existing one.
2. Go to **APIs & Services → OAuth consent screen**. Choose **External**, enter the app name and support email, and add the Gmail accounts you will use for testing under **Test users**.
3. Open **APIs & Services → Credentials → Create credentials → OAuth client ID**. Create these two clients in the same Google Cloud project:
   - **Web application**: copy the Client ID. In the steps below, this is called `WEB_CLIENT_ID`.
   - **Android**: enter the app's `applicationId` from `android/app/build.gradle` or `android/app/build.gradle.kts`, and add the SHA-1 fingerprint for the signing key you use.

To find the debug SHA-1 on Windows, run this in the `mobile` folder:

```powershell
cd android
.\gradlew signingReport
```

You can also check the debug keystore at `%USERPROFILE%\.android\debug.keystore`.

## 2. Configure the backend

For local development, add this to `backend/.env`:

```env
GOOGLE_CLIENT_ID=WEB_CLIENT_ID
```

Replace `WEB_CLIENT_ID` with your actual Web application Client ID, then rebuild the local backend:

```bash
docker compose up -d --build
```

If you are using the deployed backend on Render, add the same `GOOGLE_CLIENT_ID` value in the Render service's environment variables as well.

## 3. Run the app

From the `mobile` folder, run:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_CLIENT_ID
```

Replace `WEB_CLIENT_ID` with the same Web application Client ID used by the backend. Use an Android emulator image with Google Play, or a real Android phone with a Google account.

If the client ID is missing, the app should show that Google Sign-In is not configured rather than crashing.

## Troubleshooting

| Error | What to check |
|---|---|
| `ApiException: 10` or setup error | Check the Android package name and SHA-1. Make sure the Android and Web clients belong to the same Google Cloud project. |
| `ApiException: 12500` | Check the OAuth consent screen's support email and Google Play Services. |
| “Access blocked: app not verified” | If the app is in testing mode, add your Gmail account under **Test users**. |
| “Invalid Google token” from the backend | Make sure the backend's `GOOGLE_CLIENT_ID` and Flutter's `GOOGLE_SERVER_CLIENT_ID` are the same Web Client ID. |

## iOS (optional)

For iOS, create an iOS OAuth client and configure `ios/Runner/Info.plist` with the iOS client ID, the Web client ID as `GIDServerClientID`, and a URL scheme using the reversed iOS client ID.
