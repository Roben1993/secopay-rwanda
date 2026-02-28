#!/usr/bin/env bash
# Build APK/AAB with secrets injected via --dart-define
# Usage: bash build.sh [apk|appbundle]

set -e

# Load .env.local if it exists
if [ -f .env.local ]; then
  export $(grep -v '^#' .env.local | xargs)
fi

PAWAPAY_API_KEY="${PAWAPAY_API_KEY:-}"

if [ -z "$PAWAPAY_API_KEY" ]; then
  echo "ERROR: PAWAPAY_API_KEY is not set. Aborting build."
  exit 1
fi

BUILD_TYPE="${1:-apk}"

flutter build "$BUILD_TYPE" --release \
  --dart-define=PAWAPAY_API_KEY="$PAWAPAY_API_KEY"

echo "Build complete."
