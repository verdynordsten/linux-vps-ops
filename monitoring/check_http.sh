#!/usr/bin/env bash
# check_http.sh — status-code + latency check, Nagios-style exit codes.
# Usage: ./monitoring/check_http.sh URL [WARN_MS=2000] [TIMEOUT_S=10]
set -euo pipefail

URL="${1:-}"; WARN_MS="${2:-2000}"; TO="${3:-10}"
[[ -n "$URL" ]] || { echo "usage: $0 URL [WARN_MS] [TIMEOUT_S]" >&2; exit 2; }

OUT="$(curl -s -o /dev/null -w '%{http_code} %{time_total}' --max-time "$TO" "$URL" 2>/dev/null || echo '000 0')"
CODE="${OUT%% *}"; SEC="${OUT##* }"
MS="$(awk -v s="$SEC" 'BEGIN{printf "%d", s*1000}')"

if [[ "$CODE" == "000" ]]; then echo "CRIT - connection failed: $URL"; exit 2; fi
if (( CODE >= 500 )); then echo "CRIT - HTTP $CODE in ${MS}ms: $URL"; exit 2; fi
if (( CODE >= 400 )); then echo "WARN - HTTP $CODE in ${MS}ms: $URL"; exit 1; fi
if (( MS >= WARN_MS )); then echo "WARN - HTTP $CODE slow (${MS}ms >= ${WARN_MS}ms): $URL"; exit 1; fi
echo "OK - HTTP $CODE in ${MS}ms: $URL"
