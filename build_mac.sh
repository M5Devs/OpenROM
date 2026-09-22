#!/bin/bash
echo "========================================"
echo "  OpenROM Build Script - macOS"
echo "  M5 Dev"
echo "========================================"

set -e

ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

if [ "$ARCH" = "arm64" ]; then
    ARCH_LABEL="arm64"
else
    ARCH_LABEL="x86_64"
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
  --macos-target-arch=$ARCH \
  --assume-yes-for-downloads \
  --quiet \
  core/cli.py

# Fix exec bit
chmod +x dist/openrom-core.dist/openrom-core 2>/dev/null || true

# Build Flutter desktop application
echo "[3/4] Building Flutter desktop application..."
cd openrom_flutter
flutter build macos --release
cd ..

# Package and sign release
echo "[4/4] Packaging and signing release..."
mkdir -p dist/release

# Copy Flutter .app bundle
cp -r openrom_flutter/build/macos/Build/Products/Release/*.app dist/release/

APP_BUNDLE=$(ls -d dist/release/*.app | head -n 1)

if [ -n "$APP_BUNDLE" ]; then
    # Copy openrom-core standalone into the app bundle
    if [ -d "dist/openrom-core.dist" ]; then
        cp -r dist/openrom-core.dist/* "$APP_BUNDLE/Contents/MacOS/"
    fi

    # Ensure exec bit
    chmod +x "$APP_BUNDLE/Contents/MacOS/openrom-core"

    # Remove quarantine flags macOS puts on downloaded files
    xattr -cr "$APP_BUNDLE"

    # Ad-hoc sign the entire bundle with entitlements
    # ("-" = ad-hoc identity, no Apple Developer account needed)
    codesign --deep --force \
      --entitlements macos_entitlements.plist \
      --sign - \
      "$APP_BUNDLE"

    echo "✅ App bundle signed with ad-hoc identity"
fi

# Copy themes and assets
[ -d "themes" ] && cp -r themes dist/release/
[ -d "assets" ] && cp -r assets dist/release/

# Create release ZIP
cd dist/release
zip -r "../OpenROM-v${VERSION:-3.0.0}_macOS_${ARCH_LABEL}.zip" .
cd ../..

echo ""
echo "✅ OpenROM macOS Release packaged in dist/release/"
echo "📦 dist/OpenROM-v${VERSION:-3.0.0}_macOS_${ARCH_LABEL}.zip is ready for release!"
