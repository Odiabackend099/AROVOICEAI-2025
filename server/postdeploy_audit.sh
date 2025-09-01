#!/usr/bin/env bash
# ODIADEV post-deploy audit (AL2023/Ubuntu). Safe to run repeatedly.
set -euo pipefail

SERVICE="odiadev-edge-tts"
APP_DIR="/opt/odiadev-edge-tts"
ENV_FILE="/etc/${SERVICE}.env"
API_BASE="${API_BASE:-http://127.0.0.1}"
N_REQ="${N_REQ:-8}"            # set N_REQ=35 for a heavier rate test
TEXT="${TEXT:-"Hello from ODIADEV in Lagos"}"
TMP_MP3="/tmp/odiadev-audit.mp3"

pass() { printf "\033[32m✔ %s\033[0m\n" "$*"; }
fail() { printf "\033[31m✖ %s\033[0m\n" "$*"; exit 1; }
warn() { printf "\033[33m⚠ %s\033[0m\n" "$*"; }

printf "\n== ODIADEV Edge-TTS Audit ==\n"

# 1) service & process
systemctl is-enabled "$SERVICE" >/dev/null 2>&1 || fail "Service not enabled"
systemctl is-active  "$SERVICE" >/dev/null 2>&1 || fail "Service not active"
pass "Systemd service running"

# 2) files & ownership
[ -s "$APP_DIR/app.py" ] || fail "Missing $APP_DIR/app.py"
[ -s "$APP_DIR/venv/bin/gunicorn" ] || fail "Missing venv/gunicorn"
stat -c "%a" "$ENV_FILE" 2>/dev/null | grep -qE '600|640' || warn "Env file perms should be 600"
pass "App files present"

# 3) env & workers
API_KEY="$(grep -E '^API_KEY=' "$ENV_FILE" | cut -d= -f2- || true)"
REQ_KEY="$(grep -E '^REQUIRE_API_KEY=' "$ENV_FILE" | cut -d= -f2- || echo true)"
WORKERS="$(grep -E '^workers\s*=' "$APP_DIR/gunicorn.conf.py" | awk -F= '{print $2}' | tr -d ' ')"
[ -n "$API_KEY" ] || warn "API_KEY not found in $ENV_FILE"
printf "Info: workers=%s require_api_key=%s\n" "${WORKERS:-?}" "${REQ_KEY:-?}"

# 4) root & health
curl -fsS "$API_BASE/" | grep -q '"ok": true' || fail "Root check failed"
pass "Root OK"

# Health is best-effort; should still be ok:true
curl -fsS "$API_BASE/health" | grep -q '"ok": true' || fail "Health check failed"
pass "Health OK"

# 5) voices (not fatal if upstream slow)
if curl -fsS "$API_BASE/voices" | grep -q '"ok": true'; then
  pass "Voices endpoint OK"
else
  warn "Voices endpoint degraded (upstream); continuing"
fi

# 6) synth small sample
if [ -n "$API_KEY" ] && [ "${REQ_KEY,,}" != "false" ]; then
  AUTH=(-H "X-API-Key: $API_KEY")
else
  AUTH=()
fi
curl -s -X POST "$API_BASE/api/speak" \
  -H "Content-Type: application/json" "${AUTH[@]}" \
  -d "{\"text\":\"$TEXT\",\"voice\":\"en-NG-EzinneNeural\",\"format\":\"mp3_48k\"}" \
  --max-time 60 --output "$TMP_MP3"
[ -s "$TMP_MP3" ] || fail "Synthesis failed"
pass "Synthesis produced $(stat -c%s "$TMP_MP3") bytes"

# 7) light rate test (defaults N_REQ=8)
OK=0; RL=0; OTHER=0
for i in $(seq 1 "$N_REQ"); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_BASE/api/speak" \
    -H "Content-Type: application/json" "${AUTH[@]}" \
    -d "{\"text\":\"Rate test $i\",\"voice\":\"en-NG-EzinneNeural\",\"format\":\"mp3_48k\"}" \
    --max-time 20)
  case "$CODE" in
    200) OK=$((OK+1));;
    429) RL=$((RL+1));;
    *)   OTHER=$((OTHER+1));;
  esac
done
printf "RateTest: ok=%d 429=%d other=%d (workers=%s)\n" "$OK" "$RL" "$OTHER" "${WORKERS:-?}"
if [ "${WORKERS:-2}" -gt 1 ]; then
  warn "Limiter is per-worker; effective cap ≈ 30×workers rpm/IP. Use workers=1 for strict 30 rpm."
fi

pass "Audit finished"
