#!/usr/bin/env bash
# logwatch.sh — failed-login / error triage for auth-style logs.
# Usage: ./monitoring/logwatch.sh [LOGFILE=/var/log/auth.log] [LINES=2000]
# Env: FAIL_CRIT=10 (exit 2 when failed-password hits >= this)
set -euo pipefail

LOG="${1:-/var/log/auth.log}"; LINES="${2:-2000}"; FAIL_CRIT="${FAIL_CRIT:-10}"
[[ -f "$LOG" ]] || { echo "error: log not found: $LOG" >&2; exit 2; }

TAIL="$(tail -n "$LINES" "$LOG")"
fails="$(grep -c -i 'failed password\|authentication failure\|failed login' <<<"$TAIL" || true)"
invalid="$(grep -c -i 'invalid user' <<<"$TAIL" || true)"
errors="$(grep -c -i 'error\|refused\|denied' <<<"$TAIL" || true)"
top_ips="$(grep -o -E 'from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' <<<"$TAIL" | sort | uniq -c | sort -rn | head -5 || true)"

echo "log: $LOG (last $LINES lines)"
echo "failed_password=$fails invalid_user=$invalid errors=$errors"
echo "top source IPs:"
[[ -n "$top_ips" ]] && echo "$top_ips" || echo "  (none)"
if (( fails >= FAIL_CRIT )); then echo "CRIT - $fails failed logins >= $FAIL_CRIT (possible brute force)"; exit 2; fi
echo "OK - below threshold ($FAIL_CRIT)"
