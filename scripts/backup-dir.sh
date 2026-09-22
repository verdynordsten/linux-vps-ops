#!/usr/bin/env bash
# backup-dir.sh — timestamped tar.gz + sha256 + retention rotation.
# Usage: ./scripts/backup-dir.sh SRC_DIR DEST_DIR [RETENTION_DAYS=14]
set -euo pipefail

usage() { echo "usage: $0 SRC_DIR DEST_DIR [RETENTION_DAYS=14]" >&2; exit 2; }
[[ $# -ge 2 ]] || usage

SRC="$1"; DEST="$2"; KEEP="${3:-14}"
[[ -d "$SRC" ]] || { echo "error: src not a directory: $SRC" >&2; exit 1; }
mkdir -p "$DEST"

TS="$(date '+%Y%m%d-%H%M%S')"
BASE="$(basename "$SRC")"
OUT="$DEST/${BASE}-${TS}.tar.gz"

tar -czf "$OUT" -C "$(dirname "$SRC")" "$BASE"
sha256sum "$OUT" > "${OUT}.sha256"

# rotate backups older than KEEP days (by mtime)
if (( KEEP >= 0 )); then
  find "$DEST" -maxdepth 1 -name "${BASE}-*.tar.gz" -mtime "+$KEEP" -delete 2>/dev/null || true
  find "$DEST" -maxdepth 1 -name "${BASE}-*.tar.gz.sha256" -mtime "+$KEEP" -delete 2>/dev/null || true
fi

echo "backup: $OUT"
echo "sha256: $(cut -d' ' -f1 "${OUT}.sha256")"
