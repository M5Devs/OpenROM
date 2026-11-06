#!/usr/bin/env bash
# test-fetch-binaries.sh — exercise scripts/fetch-binaries.sh against a local
# HTTP fixture. Covers: success, checksum mismatch (exit 4), multiple archs
# without --arch (exit 1), single arch, invalid --os, and OPENROM_BINS_REF
# handling.
#
# Usage: scripts/test-fetch-binaries.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/fetch-binaries.sh"

WORK="$(mktemp -d)"
SERVER_PID=""
# shellcheck disable=SC2317  # invoked indirectly via the EXIT trap
cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

failures=0
check() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "ok   - $desc (exit $actual)"
    else
        echo "FAIL - $desc (expected exit $expected, got $actual)"
        failures=$((failures + 1))
    fi
}

# ── Fixture ──────────────────────────────────────────────────────────────
FIX="$WORK/fixture"
mkdir -p "$FIX/linux/x86_64" "$FIX/linux/arm64" \
         "$FIX/windows/x86_64" "$FIX/macos/arm64"

printf 'A' > "$FIX/linux/x86_64/chdman"
printf 'B' > "$FIX/linux/arm64/chdman"
printf 'C' > "$FIX/macos/arm64/maxcso"
printf 'W' > "$FIX/windows/x86_64/chdman.exe"
# A decoupled tool, published with a valid hash — it must be ignored.
printf 'N' > "$FIX/linux/x86_64/nkit"

sha() { sha256sum "$1" | awk '{print $1}'; }

{
    echo "$(sha "$FIX/linux/x86_64/chdman")  linux/x86_64/chdman"
    echo "$(sha "$FIX/linux/arm64/chdman")  linux/arm64/chdman"
    echo "$(sha "$FIX/macos/arm64/maxcso")  macos/arm64/maxcso"
    echo "$(sha "$FIX/linux/x86_64/nkit")  linux/x86_64/nkit"
    # Deliberately wrong hash to trigger exit 4.
    echo "0000000000000000000000000000000000000000000000000000000000000000  windows/x86_64/chdman.exe"
} > "$FIX/checksums.sha256"

PORT=$(( (RANDOM % 20000) + 20000 ))
python3 -m http.server "$PORT" --directory "$FIX" >/dev/null 2>&1 &
SERVER_PID=$!
sleep 1

export OPENROM_BINS_BASE_URL="http://127.0.0.1:$PORT"
export OPENROM_BINS_CHECKSUMS_URL="http://127.0.0.1:$PORT/checksums.sha256"

echo "── success: linux/x86_64 ──────────────────────────────"
bash "$SCRIPT" --os linux --arch x86_64 --dest "$WORK/out1" >/dev/null 2>&1
check "success fetch" 0 $?
[ -f "$WORK/out1/chdman" ] && echo "ok   - chdman present"
if [ ! -f "$WORK/out1/chdman" ]; then
    echo "FAIL - chdman missing"
    failures=$((failures + 1))
fi
if [ -f "$WORK/out1/nkit" ]; then
    echo "FAIL - decoupled tool nkit was downloaded"
    failures=$((failures + 1))
else
    echo "ok   - decoupled tool nkit skipped"
fi

echo "── wrong hash -> exit 4 ───────────────────────────────"
bash "$SCRIPT" --os windows --arch x86_64 --dest "$WORK/out2" >/dev/null 2>&1
check "checksum mismatch" 4 $?
[ -f "$WORK/out2/chdman.exe" ] \
    && { echo "FAIL - mismatched file kept"; failures=$((failures + 1)); } \
    || echo "ok   - mismatched file removed"

echo "── multiple archs without --arch -> exit 1 ────────────"
bash "$SCRIPT" --os linux --dest "$WORK/out3" >/dev/null 2>&1
check "ambiguous arch" 1 $?

echo "── single arch without --arch -> exit 0 ───────────────"
bash "$SCRIPT" --os macos --dest "$WORK/out4" >/dev/null 2>&1
check "macos single arch" 0 $?
[ -f "$WORK/out4/maxcso" ] && echo "ok   - maxcso present"
if [ ! -f "$WORK/out4/maxcso" ]; then
    echo "FAIL - maxcso missing"
    failures=$((failures + 1))
fi

echo "── android is no longer a valid --os -> exit 1 ────────"
bash "$SCRIPT" --os android --dest "$WORK/out_android" >/dev/null 2>&1
check "android rejected" 1 $?

echo "── OPENROM_BINS_REF is used in the default URL ────────"
unset OPENROM_BINS_CHECKSUMS_URL
out=$(OPENROM_BINS_REF=custom-ref bash "$SCRIPT" --os macos --dest "$WORK/out5" 2>&1)
echo "$out" | head -1
if echo "$out" | grep -q "OpenROM-bins/custom-ref/checksums.sha256"; then
    echo "ok   - custom ref appears in checksums URL"
else
    echo "FAIL - custom ref not used"
    failures=$((failures + 1))
fi

echo "── invalid OPENROM_BINS_REF -> exit 1 ─────────────────"
OPENROM_BINS_REF='bad ref!' bash "$SCRIPT" --os macos --dest "$WORK/out6" >/dev/null 2>&1
check "invalid ref" 1 $?

echo
if [ "$failures" -eq 0 ]; then
    echo "ALL CHECKS PASSED"
    exit 0
fi
echo "$failures CHECK(S) FAILED"
exit 1
