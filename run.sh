#!/usr/bin/env bash
# Run the app with all secrets injected via --dart-define
# Usage: bash run.sh [device-id]

set -e

# Load .env.local if it exists
if [ -f .env.local ]; then
  export $(grep -v '^#' .env.local | xargs)
fi

PAWAPAY_API_KEY="${PAWAPAY_API_KEY:-}"

if [ -z "$PAWAPAY_API_KEY" ]; then
  echo "WARNING: PAWAPAY_API_KEY is not set. PawaPay features will be disabled."
fi

DEVICE_ARG=""
if [ -n "$1" ]; then
  DEVICE_ARG="-d $1"
fi

flutter run $DEVICE_ARG \
  --dart-define=PAWAPAY_API_KEY="$PAWAPAY_API_KEY"
