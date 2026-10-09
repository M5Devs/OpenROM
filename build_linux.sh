#!/usr/bin/env bash
set -e

if [ -d "bins" ]; then
  echo "=== Verifying OpenROM-bins checksums ==="
  (cd bins && tr -d '\r' < checksums.sha256 | sha256sum -c -)
fi

echo "=== Building OpenROM Core (Dart CLI) ==="
cd core
dart pub get
dart compile exe bin/openrom.dart -o ../openrom-core
cd ..

echo "=== Building OpenROM Flutter UI ==="
cd gui
flutter pub get
flutter build linux --release
cd ..

echo "=== Build Complete ==="
