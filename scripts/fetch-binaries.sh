#!/usr/bin/env bash
# fetch-binaries.sh — Download OpenROM third-party tool binaries from SourceForge
# and verify each one against the published checksums.sha256 before use.
#
# Usage:
#   scripts/fetch-binaries.sh --os <os> [--arch <arch>] --dest <dir>
#
#   --os    linux | macos | windows | android
#   --arch  x86_64 | arm64 | arm64-v8a   (omit to fetch every arch published for the OS)
#   --dest  destination directory (files are placed flat, by basename)
#
# Examples:
#   scripts/fetch-binaries.sh --os windows --arch x86_64 --dest assets/windows
#   scripts/fetch-binaries.sh --os linux   --arch arm64  --dest assets/linux/arm64
#   scripts/fetch-binaries.sh --os macos   --arch arm64  --dest assets/macos/arm64
#
# Exit codes:
#   0 success
#   1 bad arguments / missing dependency
#   2 no matching binaries in checksums.sha256
#   3 download failed
#   4 checksum verification mismatch

set -euo pipefail

BASE_URL="${OPENROM_BINS_BASE_URL:-https://downloads.sourceforge.net/project/openrom-binaries}"
CHECKSUMS_URL="${OPENROM_BINS_CHECKSUMS_URL:-https://raw.githubusercontent.com/M5Devs/OpenROM-bins/main/checksums.sha256}"

OS=""
ARCH=""
DEST=""

usage() {
    sed -n '2,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --os)   OS="$2"; shift 2 ;;
        --arch) ARCH="$2"; shift 2 ;;
        --dest) DEST="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

[[ -n "$OS" && -n "$DEST" ]] || usage

case "$OS" in
    linux|macos|windows|android) ;;
    *) echo "Invalid --os: $OS (expected linux, macos, windows or android)" >&2; exit 1 ;;
esac

# Prefer curl, fall back to wget.
if command -v curl >/dev/null 2>&1; then
    download() { curl -sS --retry 5 --retry-delay 2 -fL --connect-timeout 30 "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
    download() { wget -q --tries=5 --timeout=30 -O "$2" "$1"; }
else
    echo "Error: curl or wget is required" >&2; exit 1
fi

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        python3 -c "import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$1"
    fi
}

tmp_checksums="$(mktemp)"
tmp_entries="$(mktemp)"
trap 'rm -f "$tmp_checksums" "$tmp_entries"' EXIT

echo "Fetching checksums from $CHECKSUMS_URL"
if ! download "$CHECKSUMS_URL" "$tmp_checksums"; then
    echo "Error: could not download checksums.sha256" >&2
    exit 3
fi

mkdir -p "$DEST"

# Match "<sha>  <os>/<arch>/<file>"; filter by arch when provided.
arch_filter="[^/]+"
[[ -n "$ARCH" ]] && arch_filter="$ARCH"

# Write matches to a temp file (avoids bash-4 `mapfile`, unavailable on macOS).
tr -d '\r' < "$tmp_checksums" \
    | awk -v os="$OS" -v arch="$arch_filter" \
      '$2 ~ "^"os"/"arch"/" { print $1" "$2 }' > "$tmp_entries"

count=$(wc -l < "$tmp_entries" | tr -d ' ')
if [ "$count" -eq 0 ]; then
    echo "Error: no binaries found for $OS/${ARCH:-*}" >&2
    exit 2
fi

echo "Fetching $count binaries for $OS/${ARCH:-*} into $DEST"

while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    expected_sha="${entry%% *}"
    rel_path="${entry##* }"
    filename="$(basename "$rel_path")"
    url="$BASE_URL/$rel_path"
    out="$DEST/$filename"

    echo "  ↓ $rel_path"
    if ! download "$url" "$out"; then
        echo "Error: download failed for $url" >&2
        rm -f "$out"
        exit 3
    fi

    actual_sha="$(sha256_of "$out")"
    if [[ "$actual_sha" != "$expected_sha" ]]; then
        echo "Error: checksum mismatch for $rel_path" >&2
        echo "  expected: $expected_sha" >&2
        echo "  actual:   $actual_sha" >&2
        rm -f "$out"
        exit 4
    fi

    if [[ "$(uname -s 2>/dev/null)" != "Windows_NT" ]]; then
        chmod +x "$out"
    fi
    echo "  ✓ $filename"
done < "$tmp_entries"

echo "Done: $count binaries verified in $DEST"
