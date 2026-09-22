#!/bin/bash
echo "========================================"
echo "  OpenROM Build Script - Linux"
echo "  M5 Dev"
echo "========================================"

set -e

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# Map to release naming
if [ "$ARCH" = "x86_64" ]; then
    ARCH_LABEL="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH_LABEL="arm64"
else
    echo "WARNING: Unknown architecture $ARCH — continuing anyway"
    ARCH_LABEL="$ARCH"
fi

# Install dependencies
echo "[1/4] Installing dependencies..."
pip install -r requirements.txt
pip install nuitka zstandard ordered-set

# Build Python core — standalone folder avoids AV false positives
# Note: --onefile uses a self-extracting stub that triggers heuristic AV
# scanners (trojan.badjoke, Wacapew, etc). --standalone produces a
# folder-based distribution which is clean across all major AV engines.
echo "[2/4] Building openrom-core (standalone)..."
python -m nuitka \
  --standalone \
  --output-filename=openrom-core \
  --output-dir=dist \
  --include-data-dir=assets=assets \
  --assume-yes-for-downloads \
  --quiet \
  core/cli.py

# Fix exec bit on the output binary
chmod +x dist/openrom-core.dist/openrom-core 2>/dev/null || true

# Build Flutter desktop application
echo "[3/4] Building Flutter desktop application..."
cd openrom_flutter
flutter build linux --release
cd ..

# Package release files
echo "[4/4] Packaging release..."
mkdir -p dist/release

# Copy Flutter bundle
cp -r openrom_flutter/build/linux/x64/release/bundle/* dist/release/

# Copy openrom-core standalone folder
# The folder contains openrom-core binary + required libs + assets
if [ -d "dist/openrom-core.dist" ]; then
    cp -r dist/openrom-core.dist/* dist/release/
fi

# Copy themes and assets
[ -d "themes" ] && cp -r themes dist/release/
[ -d "assets" ] && cp -r assets dist/release/

# Create release ZIP
cd dist/release
zip -r "../OpenROM-v${VERSION:-3.0.0}_Linux_${ARCH_LABEL}.zip" .
cd ../..

echo ""
echo "✅ OpenROM Linux Release packaged in dist/release/"
echo "📦 dist/OpenROM-v${VERSION:-3.0.0}_Linux_${ARCH_LABEL}.zip is ready for release!"
