#!/bin/bash
echo "========================================"
echo "  OpenROM Build Script - macOS"
echo "  M5 Dev"
echo "========================================"

set -e

ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Install dependencies
echo "[1/4] Installing dependencies..."
pip install -r requirements.txt
pip install nuitka zstandard ordered-set

# Build Python core executable
echo "[2/4] Building openrom-core executable..."
python -m nuitka \
  --onefile \
  --output-filename=openrom-core \
  --output-dir=dist \
  --include-data-dir=assets=assets \
  --macos-target-arch=$ARCH \
  --assume-yes-for-downloads \
  --quiet \
  core/cli.py

# Build Flutter desktop application
echo "[3/4] Building Flutter desktop application..."
cd openrom_flutter
flutter build macos --release
cd ..

# Package release files
echo "[4/4] Packaging release..."
mkdir -p dist/release
cp -r openrom_flutter/build/macos/Build/Products/Release/*.app dist/release/
APP_BUNDLE=$(ls -d dist/release/*.app | head -n 1)
if [ -n "$APP_BUNDLE" ]; then
  cp dist/openrom-core "$APP_BUNDLE/Contents/MacOS/"
fi
cp dist/openrom-core dist/release/
if [ -d "themes" ]; then cp -r themes dist/release/; fi
if [ -d "assets" ]; then cp -r assets dist/release/; fi

cd dist/release
zip -r "OpenROM_macOS_${ARCH}.zip" .
echo "📦 dist/release/OpenROM_macOS_${ARCH}.zip is ready for release!"
