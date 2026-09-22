#!/usr/bin/env bash
# health-check.sh — threshold check with Nagios-style exit codes.
#   exit 0 = OK, 1 = WARN, 2 = CRIT
# Env knobs: DISK_WARN=80 DISK_CRIT=90 MEM_CRIT=90 LOAD_CRIT_PER_CPU=2.0
# Usage: ./scripts/health-check.sh
set -euo pipefail

DISK_WARN="${DISK_WARN:-80}"
DISK_CRIT="${DISK_CRIT:-90}"
MEM_CRIT="${MEM_CRIT:-90}"
LOAD_CRIT="${LOAD_CRIT_PER_CPU:-2.0}"

disk_used="$(df -P / | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
mem_total="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
mem_avail="$(awk '/MemAvailable/{print $2}' /proc/meminfo)"
mem_used="$(( (mem_total - mem_avail) * 100 / mem_total ))"
load1="$(cut -d' ' -f1 /proc/loadavg)"
cpus="$(nproc)"

# load per cpu, float compare via awk
load_per_cpu="$(awk -v l="$load1" -v c="$cpus" 'BEGIN{printf "%.2f", l/c}')"
load_over="$(awk -v l="$load_per_cpu" -v t="$LOAD_CRIT" 'BEGIN{print (l>=t)}')"

status="OK"; code=0
msgs=()

if (( disk_used >= DISK_CRIT )); then status="CRIT"; code=2; msgs+=("disk ${disk_used}% >= ${DISK_CRIT}%");
elif (( disk_used >= DISK_WARN )); then status="WARN"; code=1; msgs+=("disk ${disk_used}% >= ${DISK_WARN}%"); fi

if (( mem_used >= MEM_CRIT )); then status="CRIT"; code=2; msgs+=("mem ${mem_used}% >= ${MEM_CRIT}%"); fi

if [[ "$load_over" == "1" ]]; then
  if [[ "$status" != "CRIT" ]]; then status="WARN"; code=1; fi
  msgs+=("load/cpu ${load_per_cpu} >= ${LOAD_CRIT}")
fi

if (( ${#msgs[@]} == 0 )); then msgs=("all healthy"); fi
printf '%s - %s | disk=%s%% mem=%s%% load_per_cpu=%s cpus=%s\n' \
  "$status" "$(IFS='; '; echo "${msgs[*]}")" "$disk_used" "$mem_used" "$load_per_cpu" "$cpus"
exit "$code"
