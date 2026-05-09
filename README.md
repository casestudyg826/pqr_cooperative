# PQR Cooperative

Flutter member, savings, loan, repayment, reporting, user-management, and backup system backed by Supabase.

## Backend

Supabase project: `mpnhnvwttnrkolhtgmzh`

Deployed backend pieces:

- Postgres tables for users, sessions, members, savings transactions, loans, repayments, backup runs, and audit events.
- RLS enabled on all public tables.
- Edge Function: `pqr-api`.
- Seed credentials preserved:
  - Administrator: `admin / admin123`
  - Treasurer: `treasurer / treasurer123`

Passwords are hashed in Postgres. Flutter receives custom session tokens from `pqr-api`; it does not store staff passwords.

## Local Development

Without Dart defines, the app falls back to a seeded in-memory backend for tests and offline UI work.

Run against Supabase:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://mpnhnvwttnrkolhtgmzh.supabase.co \
  --dart-define=SUPABASE_FUNCTION_SLUG=pqr-api
```

Run checks:

```bash
flutter pub get
flutter analyze
flutter test
```

Build web against Supabase:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://mpnhnvwttnrkolhtgmzh.supabase.co \
  --dart-define=SUPABASE_FUNCTION_SLUG=pqr-api
```

## Vercel

The repository includes `vercel.json` and `scripts/vercel-build.sh`. Configure these Vercel environment variables:

- `SUPABASE_URL`: `https://mpnhnvwttnrkolhtgmzh.supabase.co`
- `SUPABASE_FUNCTION_SLUG`: `pqr-api` (optional, defaults to `pqr-api`)

Vercel builds Flutter web into `build/web` and serves it as a static app.

## Supabase Files

- `supabase/migrations/20260509000000_pqr_backend.sql`
- `supabase/migrations/20260509001000_fix_pgcrypto_function_search_path.sql`
- `supabase/functions/pqr-api/index.ts`
