#!/usr/bin/env bash
# purge_sf_deprecated_binaries.sh — remove decoupled tool binaries from the
# SourceForge `openrom-binaries` FRS project.
#
# v4.0.0 decoupled nkit, saturn-patcher, xgdtool and extract-xiso from OpenROM
# Core; they now ship as `.orplug` plugins from the OpenROM Extension Store.
# This script removes the stale copies from the release host so
# scripts/fetch-binaries.sh can never re-download them.
#
# The six core utilities — chdman, nodtool, maxcso, xdelta3, ecm, unecm — are
# never touched.
#
# Usage:
#   scripts/purge_sf_deprecated_binaries.sh [--dry-run]
#
# Environment:
#   SF_USER   SourceForge username (required)
#   SF_PASS   SourceForge password (required)
#
# Notes:
#   * SourceForge exposes a restricted shell: `ssh <cmd>` returns nothing, so
#     deletion goes through rsync's `--delete-missing-args` with a source that
#     deliberately does not exist.
#   * Auth is keyboard-interactive only; `sshpass -e` (env var, not argv) keeps
#     the password out of the process table.
#
# Exit codes:
#   0 success (including "nothing to delete")
#   1 bad arguments / missing dependency / missing credentials
#   3 a remote deletion failed
#   4 post-purge verification failed

set -uo pipefail

FRS_HOST="frs.sourceforge.net"
FRS_ROOT="/home/frs/project/openrom-binaries"

CORE_TOOLS=(chdman nodtool maxcso xdelta3 ecm unecm)

# "<remote dir relative to FRS_ROOT>|<space-separated files to remove>"
PURGE_TARGETS=(
    "windows/x86_64|nkit.exe saturn-patcher.exe xgdtool.exe XGDTool.exe extract-xiso.exe"
    "linux/x86_64|nkit saturn-patcher xgdtool XGDTool extract-xiso"
    "linux/arm64|nkit saturn-patcher xgdtool XGDTool extract-xiso"
    "macos/arm64|nkit saturn-patcher extract-xiso"
    "macos/x86_64|nkit saturn-patcher extract-xiso"
    "android/arm64-v8a|nkit"
)

DRY_RUN=0

usage() {
    sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

for dep in sshpass rsync; do
    command -v "$dep" >/dev/null 2>&1 || {
        echo "Error: '$dep' is required but not installed." >&2
        exit 1
    }
done

[[ -n "${SF_USER:-}" ]] || { echo "Error: SF_USER is not set." >&2; exit 1; }
[[ -n "${SF_PASS:-}" ]] || { echo "Error: SF_PASS is not set." >&2; exit 1; }

# sshpass -e reads the password from SSHPASS, never from argv.
export SSHPASS="$SF_PASS"

RSH=(ssh
    -o StrictHostKeyChecking=no
    -o PreferredAuthentications=keyboard-interactive
    -o PubkeyAuthentication=no
    -o ConnectTimeout=30)

REMOTE="$SF_USER@$FRS_HOST:$FRS_ROOT"

# rsync prints a harmless "Could not chdir to home directory" banner on login.
# The banner is filtered on stdout, but the *rsync* exit code is what we return
# — piping straight into grep would report grep's status instead.
rsync_remote() {
    local out rc
    out="$(sshpass -e rsync -e "${RSH[*]}" "$@" 2>&1)"
    rc=$?
    printf '%s\n' "$out" | grep -v "^Could not chdir to home directory"
    return "$rc"
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
EMPTY="$WORK/empty-source"
mkdir -p "$EMPTY"

echo "SourceForge purge — $FRS_ROOT"
[[ "$DRY_RUN" == "1" ]] && echo "*** DRY RUN — no remote changes will be made ***"
echo

deleted_total=0
failures=0

for target in "${PURGE_TARGETS[@]}"; do
    dir="${target%%|*}"
    files="${target#*|}"
    echo "── $dir"

    # Which of the listed files actually exist remotely?
    listing="$(rsync_remote --list-only -r "$REMOTE/$dir/")"
    present=()
    for f in $files; do
        if grep -q " [0-9,]\+ [0-9/: ]\+ $f\$" <<<"$listing"; then
            present+=("$f")
        fi
    done

    if [[ ${#present[@]} -eq 0 ]]; then
        echo "   nothing to delete"
        continue
    fi

    echo "   removing: ${present[*]}"
    if [[ "$DRY_RUN" == "1" ]]; then
        deleted_total=$((deleted_total + ${#present[@]}))
        continue
    fi

    # Point rsync at sources that do not exist; with --delete-missing-args it
    # removes the matching remote entries and leaves everything else alone.
    src_args=()
    for f in "${present[@]}"; do
        src_args+=("$EMPTY/$f")
    done

    if rsync_remote --delete-missing-args --ignore-missing-args -d \
        "${src_args[@]}" "$REMOTE/$dir/" >/dev/null; then
        deleted_total=$((deleted_total + ${#present[@]}))
        echo "   ✓ removed ${#present[@]} file(s)"
    else
        echo "   ✗ rsync failed for $dir" >&2
        failures=$((failures + 1))
    fi
done

echo
if [[ "$failures" -gt 0 ]]; then
    echo "Error: $failures directory operation(s) failed." >&2
    exit 3
fi

if [[ "$DRY_RUN" == "1" ]]; then
    echo "Dry run complete: $deleted_total file(s) would be removed."
    exit 0
fi

echo "Deleted $deleted_total file(s). Verifying…"

# ── Verify ────────────────────────────────────────────────────────────────
verify_failures=0
for target in "${PURGE_TARGETS[@]}"; do
    dir="${target%%|*}"
    files="${target#*|}"
    listing="$(rsync_remote --list-only -r "$REMOTE/$dir/")"

    for f in $files; do
        if grep -q " [0-9,]\+ [0-9/: ]\+ $f\$" <<<"$listing"; then
            echo "  ✗ still present: $dir/$f" >&2
            verify_failures=$((verify_failures + 1))
        fi
    done

    for tool in "${CORE_TOOLS[@]}"; do
        if ! grep -q " [0-9,]\+ [0-9/: ]\+ $tool\\(.exe\\)\\?\$" <<<"$listing"; then
            # The Android build publishes no nodtool; every other platform
            # ships all six core utilities.
            [[ "$dir:$tool" == "android/arm64-v8a:nodtool" ]] && continue
            echo "  ✗ core tool missing: $dir/$tool" >&2
            verify_failures=$((verify_failures + 1))
        fi
    done
    echo "  ✓ $dir clean"
done

echo
if [[ "$verify_failures" -gt 0 ]]; then
    echo "Error: verification failed ($verify_failures issue(s))." >&2
    exit 4
fi

echo "Done: deprecated binaries purged; core 6 utilities intact."
