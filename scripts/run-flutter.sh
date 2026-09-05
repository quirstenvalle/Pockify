#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../flutter_app"
flutter pub get
if flutter devices | grep -qiE 'edge|chrome'; then
  if flutter devices | grep -qi edge; then
    exec flutter run -d edge
  fi
  exec flutter run -d chrome
fi
exec flutter run
