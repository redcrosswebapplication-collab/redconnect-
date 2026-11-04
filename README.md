# RedCross Connect+

Flutter app (`app/`) and the optional Node REST API (`backend/`) use Supabase Auth, Postgres, and private Storage. Both share the same Supabase project and application data.

## Set up Supabase

1. Create a Supabase project and open **SQL Editor**.
2. Run [`supabase/schema.sql`](./supabase/schema.sql) to create the tables, row-level security policies, booking/request RPCs, and private ID-photo bucket.
3. This app is configured with the supplied project URL and publishable key. To override them for another environment, pass `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as Dart defines. Never use a `service_role` key in the Flutter app.
4. In **Authentication → Providers → Email**, turn off **Confirm email** to let users sign in immediately after signup. Enable Google under **Authentication → Providers**, add `io.supabase.flutter://login-callback/` to the project's allowed redirect URLs for mobile, and configure the provider's Google OAuth credentials. For password recovery, set the recovery email template to include `{{ .Token }}` so the app's six-digit-code form can verify it.
5. To grant an account admin access for review workflows, run this in the SQL Editor after it has signed up:
   ```sql
   update public.profiles set role = 'admin'
   where email = lower('admin@example.com');
   ```

## Run the Node API

The Flutter app accesses Supabase directly. To run the separate REST API for other clients, copy `backend/.env.example` to `backend/.env` and set the project URL, publishable key, and server-only service-role key. Then run `npm install` and `npm start` from `backend/`. Never put the service-role key in the Flutter app or commit it. The API validates bearer tokens with Supabase Auth and uses the same tables, RPCs, and private Storage bucket as the app.

The previous Node API stored data in `backend/data/redcross.db`; that file is left untouched but is no longer read. Its local account used a legacy password hash that Supabase Auth cannot import. The bundled database contains only the seeded admin and welcome notification, so create the admin in Supabase using the SQL above.

Supabase Auth creates each `profiles` row through a database trigger. RLS restricts user records to their owner; donor ID images are stored in the private `donor-ids` bucket.

## Run the app

Requires Flutter 3.22+.

```powershell
cd app
flutter pub get
flutter run
```

The publishable key is intended for client apps; database security depends on the RLS policies in the schema. Do not put database passwords or the Supabase `service_role` key in Dart defines.

The app and Node API support email/password sign-in, email OTP password recovery, appointment booking, blood requests, donor verification uploads, membership card requests, and notifications.

## Platform permissions

For Android, verify `android/app/src/main/AndroidManifest.xml` includes `INTERNET` and `CAMERA` permissions. For iOS, configure camera and photo-library usage descriptions in `ios/Runner/Info.plist`.
