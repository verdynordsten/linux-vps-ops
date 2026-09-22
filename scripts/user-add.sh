#!/usr/bin/env bash
# user-add.sh — idempotent user provisioning. Dry-run by default.
# Usage: ./scripts/user-add.sh USERNAME [--dry-run|--apply] [--ssh-key-file PATH]
# Real changes need root; without root the script refuses (unless --dry-run).
set -euo pipefail

DRY=1; KEYFILE=""
USERN="${1:-}"
shift || true
[[ -n "$USERN" ]] || { echo "usage: $0 USERNAME [--dry-run|--apply] [--ssh-key-file PATH]" >&2; exit 2; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --apply) DRY=0 ;;
    --ssh-key-file) KEYFILE="${2:-}"; shift ;;
    -h|--help) echo "usage: $0 USERNAME [--dry-run|--apply] [--ssh-key-file PATH]"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

if id "$USERN" &>/dev/null; then
  echo "exists: user '$USERN' already present — nothing to do"
  exit 0
fi

CMDS=("useradd -m -s /bin/bash $USERN" "passwd -l $USERN")
if [[ -n "$KEYFILE" ]]; then
  [[ -f "$KEYFILE" ]] || { echo "error: key file not found: $KEYFILE" >&2; exit 1; }
  CMDS+=("install -d -m 700 -o $USERN /home/$USERN/.ssh"
          "install -m 600 -o $USERN /dev/stdin /home/$USERN/.ssh/authorized_keys < $KEYFILE")
fi

if (( DRY )); then
  echo "dry-run: would execute:"
  printf '  %s\n' "${CMDS[@]}"
  exit 0
fi

(( EUID == 0 )) || { echo "error: --apply needs root (re-run with sudo)" >&2; exit 1; }
for c in "${CMDS[@]}"; do eval "$c"; done
echo "created: user '$USERN'"
