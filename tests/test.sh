#!/usr/bin/env bash
# Self-test: bash + python3 stdlib only. Exit non-zero on first failure.
set -euo pipefail
cd "$(dirname "$0")/.."

pass=0; fail=0
ok()   { pass=$((pass+1)); echo "  ok: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }

echo "[1] bash syntax"
for f in scripts/*.sh monitoring/*.sh tests/test.sh; do
  if bash -n "$f"; then ok "syntax $f"; else bad "syntax $f"; fi
done

echo "[2] sysinfo runs"
out="$(./scripts/sysinfo.sh 2>/dev/null)"
if grep -q "UPTIME" <<<"$out"; then ok "sysinfo"; else bad "sysinfo"; fi

echo "[3] health-check exit code valid"
./scripts/health-check.sh >/dev/null 2>&1; rc=$?
if [[ $rc -le 2 ]]; then ok "health-check rc=$rc"; else bad "health-check rc=$rc"; fi

echo "[4] backup roundtrip + rotation"
rm -rf /tmp/vops-test && mkdir -p /tmp/vops-test/src && echo hello > /tmp/vops-test/src/a.txt
if ./scripts/backup-dir.sh /tmp/vops-test/src /tmp/vops-test/dest 0 >/dev/null; then
  if ls /tmp/vops-test/dest/src-*.tar.gz >/dev/null 2>&1; then ok "backup created"; else bad "backup file missing"; fi
  f="$(ls /tmp/vops-test/dest/src-*.tar.gz | head -1)"
  if sha256sum -c "${f}.sha256" >/dev/null 2>&1; then ok "sha256 verifies"; else bad "sha256 mismatch"; fi
  touch -d '5 days ago' /tmp/vops-test/dest/src-old-20000101-000000.tar.gz
  ./scripts/backup-dir.sh /tmp/vops-test/src /tmp/vops-test/dest 1 >/dev/null
  if [[ ! -f /tmp/vops-test/dest/src-old-20000101-000000.tar.gz ]]; then ok "rotation deletes old"; else bad "rotation kept old"; fi
else bad "backup-dir run"; fi
rm -rf /tmp/vops-test

echo "[5] user-add dry-run + existing-user path"
if ./scripts/user-add.sh deploy --dry-run | grep -q "dry-run\|exists"; then ok "user-add dry-run"; else bad "user-add dry-run"; fi
if ./scripts/user-add.sh root 2>/dev/null | grep -q "exists"; then ok "user-add existing"; else bad "user-add existing"; fi
out="$(./scripts/user-add.sh nobodyhere123 --apply 2>&1 || true)"
if grep -q "needs root" <<<"$out"; then ok "user-add refuse no-root"; else bad "user-add refuse no-root"; fi

echo "[6] check_http against local server"
python3 -m http.server 18923 >/dev/null 2>&1 &
SRV=$!
ready=0
for i in $(seq 1 15); do
  if curl -s -o /dev/null --max-time 1 http://127.0.0.1:18923/ 2>/dev/null; then ready=1; break; fi
  sleep 1
done
if [[ $ready -eq 1 ]]; then ok "test server up"; else bad "test server up"; fi
if ./monitoring/check_http.sh http://127.0.0.1:18923/ | grep -q "^OK"; then ok "http OK case"; else bad "http OK case"; fi
out="$(./monitoring/check_http.sh http://127.0.0.1:18999/ 2>/dev/null || true)"
if grep -q "^CRIT" <<<"$out"; then ok "http CRIT case"; else bad "http CRIT case"; fi
kill $SRV 2>/dev/null || true

echo "[7] logwatch triage"
printf 'Failed password for root from 1.2.3.4 port 1 ssh2\nAccepted password for u from 5.6.7.8\nerror: something\n' > /tmp/vops-auth.log
if FAIL_CRIT=99 ./monitoring/logwatch.sh /tmp/vops-auth.log 5 | grep -q "failed_password=1"; then ok "logwatch counts"; else bad "logwatch counts"; fi
if FAIL_CRIT=1 ./monitoring/logwatch.sh /tmp/vops-auth.log 5 >/dev/null 2>&1; then bad "logwatch threshold"; else ok "logwatch CRIT on threshold"; fi
rm -f /tmp/vops-auth.log

echo
echo "pass=$pass fail=$fail"
[[ $fail -eq 0 ]]
