#!/bin/bash
echo "========================================"
echo "  OpenROM Build Script - Linux"
echo "  M5 Dev"
echo "========================================"

set -e

# Install dependencies
echo "[1/4] Installing dependencies..."
pip install -r requirements.txt
pip install "pyinstaller>=6.0.0"

# Build Python core executable
echo "[2/4] Building openrom-core executable..."
pyinstaller \
  --noconfirm \
  --onefile \
  --name "openrom-core" \
  --add-data "assets:assets" \
  core/cli.py

# Build Flutter desktop application
echo "[3/4] Building Flutter desktop application..."
cd openrom_flutter
flutter build linux --release
cd ..

# Package release files
echo "[4/4] Packaging release..."
mkdir -p dist/release
cp -r openrom_flutter/build/linux/x64/release/bundle/* dist/release/
cp dist/openrom-core dist/release/
if [ -d "themes" ]; then cp -r themes dist/release/; fi
if [ -d "assets" ]; then cp -r assets dist/release/; fi

echo ""
echo "✅ OpenROM Linux Release packaged in dist/release/"
