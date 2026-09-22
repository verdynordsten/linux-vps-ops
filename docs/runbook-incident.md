# Incident runbook

Copy this file per incident: `cp docs/runbook-incident.md docs/inc-YYYY-MM-DD-short-name.md`.

## 1. What happened
- Service / host:
- Detected at (UTC):
- Detected by (monitoring / ticket / user report):
- Symptom:

## 2. How I handled it
1. Triage: `./scripts/sysinfo.sh`, `./scripts/health-check.sh`
2. Scope: single host / fleet-wide?
3. Root cause (evidence, not guesses — paste log lines):
4. Fix applied (exact commands):

## 3. What resulted
- Time to resolve:
- Verification (what proves it is fixed):
- Follow-up: backup restored? config changed? monitoring added?

## 4. Prevention
- Monitoring gap to close:
- Doc to update:
