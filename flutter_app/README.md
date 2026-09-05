# Pockify Flutter app

This is the app co-devs run day to day. The Lovable web project stays at the repo root.

## Run

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then:

```bash
cd flutter_app
flutter pub get
flutter run -d edge    # Windows
flutter run -d chrome  # macOS / Linux
```

In Cursor/VS Code: **Run and Debug → Pockify Flutter (Edge)** or **(Chrome)**.

Do not put a machine-specific Flutter path in this repo. Use the SDK on your PATH.

## Shared backend

Supabase URL and the publishable key are already in `lib/api/api_config.dart`. You do not need a local `.env` for Google sign-in or email OTP.

- **Google sign-in** uses the shared Supabase Google provider. After Google, the app returns to `http://localhost:<port>`. That origin must stay in Supabase **Authentication → URL Configuration → Redirect URLs** as `http://localhost:*` and `http://127.0.0.1:*`.
- **Email OTP** is sent to the address used at signup (Gmail included) via FormSubmit. The team inbox is already activated; new users are CC'd. Check Inbox, Promotions, and Spam.

## Tests

```bash
cd flutter_app
flutter test
```
