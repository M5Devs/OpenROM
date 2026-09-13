#!/bin/bash
echo "========================================"
echo "  OpenROM Build Script - Linux"
echo "  M5 Dev"
echo "========================================"

set -e

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
  --assume-yes-for-downloads \
  --quiet \
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
