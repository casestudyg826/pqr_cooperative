#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ]; then
  echo "SUPABASE_URL is required for Vercel builds."
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${VERCEL_PROJECT_ROOT:-$PWD}/.vercel/flutter"
  if [ ! -d "$FLUTTER_HOME" ]; then
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter config --enable-web
flutter pub get
flutter build web \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_FUNCTION_SLUG="${SUPABASE_FUNCTION_SLUG:-pqr-api}"
