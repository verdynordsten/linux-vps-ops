#!/usr/bin/env bash
# sysinfo.sh — one-shot server snapshot for triage / shift handover.
# Usage: ./scripts/sysinfo.sh
# Read-only. Works on any Linux with /proc (no root needed).
set -euo pipefail

section() { printf '\n== %s ==\n' "$1"; }

section "HOST"
hostname; echo "date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

section "OS"
if [[ -f /etc/os-release ]]; then grep -E '^(NAME|VERSION)=' /etc/os-release; else uname -a; fi
echo "kernel: $(uname -r)"; echo "arch: $(uname -m)"

section "UPTIME"
uptime

section "DISK /"
df -h / | awk 'NR==1 || NR==2'

section "MEMORY"
free -h

section "LOAD (1/5/15m, cpus)"
echo "$(cut -d' ' -f1-3 /proc/loadavg) | cpus: $(nproc)"

section "TOP MEM PROCESSES"
ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -6
