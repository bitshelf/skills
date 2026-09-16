#!/bin/bash
# Execute command on remote Windows via SSH.
# Auth: key-based by default, password if WIN_PASS is set (requires sshpass).
# Config: .win-target.conf found by walking up from $PWD.
# https://learn.microsoft.com/windows-server/administration/openssh/openssh_keymanagement
set -euo pipefail

# ── Help ──
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat << 'EOF'
Usage: run.sh <command>

Execute <command> on remote Windows machine via SSH.
Finds .win-target.conf by walking up from $PWD.

Config (.win-target.conf):
  WIN_HOST=<ip-or-hostname>          # required
  WIN_USER=<username>                # required
  WIN_PASS=<password>               # optional — password auth (needs sshpass)
  PLATFORM_TOOLS=<windows-path>     # optional — path to tools on Windows

Auth: key-based by default. Password auth via sshpass if WIN_PASS is set.

Environment:
  WIN_CONF      override config path
  WIN_CONF_DIR  override search start directory (default: $PWD)

Examples:
  run.sh dir C:\\remote_winspace
  run.sh "& 'D:\\tools\\adb.exe' devices"

See https://learn.microsoft.com/windows-server/administration/openssh/openssh_keymanagement
EOF
    exit 0
fi

# ── Locate .win-target.conf by walking up from $PWD ──
find_config() {
    local dir="$1"
    while :; do
        if [ -f "$dir/.win-target.conf" ]; then
            echo "$dir/.win-target.conf"
            return 0
        fi
        [ "$dir" = "/" ] && break
        dir=$(dirname "$dir")
    done
    return 1
}

CONF="${WIN_CONF:-$(find_config "${WIN_CONF_DIR:-$PWD}" || true)}"
if [ -z "$CONF" ] || [ ! -f "$CONF" ]; then
    echo "ERROR: .win-target.conf not found (walked up from ${WIN_CONF_DIR:-$PWD})" >&2
    exit 1
fi
source "$CONF"

# ── Validate required vars ──
if [ -z "${WIN_HOST:-}" ] || [ -z "${WIN_USER:-}" ]; then
    echo "ERROR: WIN_HOST and WIN_USER must be set in $CONF" >&2
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 <command>  (run with --help for details)" >&2
    exit 1
fi

# ── Auth: password-based if WIN_PASS is set, otherwise key-based ──
SSH_OPTS=(
    -o StrictHostKeyChecking=accept-new
    -o ConnectTimeout=10
)

if [ -n "${WIN_PASS:-}" ]; then
    # Password auth via sshpass
    if ! command -v sshpass &>/dev/null; then
        echo "ERROR: WIN_PASS set but sshpass not installed" >&2
        exit 1
    fi
    export SSHPASS="$WIN_PASS"
    SSH_CMD=(sshpass -e ssh "${SSH_OPTS[@]}" "${WIN_USER}@${WIN_HOST}" "$1")
else
    SSH_OPTS+=(-o PasswordAuthentication=no)
    SSH_CMD=(ssh "${SSH_OPTS[@]}" "${WIN_USER}@${WIN_HOST}" "$1")
fi

# ── Run command ──
ERRFILE=$(mktemp)
trap 'rm -f "$ERRFILE"' EXIT

rc=0
"${SSH_CMD[@]}" 2>"$ERRFILE" || rc=$?

# Filter known PowerShell profile noise (not real errors)
grep -v \
    -e 'Set-PSReadLineOption' \
    -e 'FullyQualifiedErrorId' \
    "$ERRFILE" >&2 || true

exit $rc
