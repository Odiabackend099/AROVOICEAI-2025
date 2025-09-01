#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/odiadev-edge-tts"
PY_BIN="python3"
PORT="8080"
SERVICE_USER="odiadev"
SERVICE_NAME="odiadev-edge-tts"
ENV_FILE="/etc/${SERVICE_NAME}.env"
NGINX_SITE="/etc/nginx/conf.d/${SERVICE_NAME}.conf"

# --------- detect package manager ---------
if command -v apt-get >/dev/null 2>&1; then
  PKG="apt"
elif command -v dnf >/dev/null 2>&1; then
  PKG="dnf"
elif command -v yum >/dev/null 2>&1; then
  PKG="yum"
else
  echo "Unsupported distro"; exit 1
fi

# --------- install deps ---------
if [ "$PKG" = "apt" ]; then
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-venv python3-pip nginx curl
else
  sudo $PKG install -y python3 python3-pip nginx curl
  $PY_BIN -m ensurepip --default-pip >/dev/null 2>&1 || true
fi

# --------- service user ---------
if ! id -u "$SERVICE_USER" >/dev/null 2>&1; then
  sudo useradd --system --create-home --shell /sbin/nologin "$SERVICE_USER"
fi

# --------- app dir ---------
sudo mkdir -p "$APP_DIR"
sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$APP_DIR"
sudo chmod 755 "$APP_DIR"

# --------- write app files ---------
sudo tee "$APP_DIR/app.py" >/dev/null <<'PY'
#!/usr/bin/env python3
import os, io, asyncio, tempfile, time, json, hashlib
from typing import Dict
from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS
import edge_tts

API_KEY=os.getenv("API_KEY","ODIADEV-KEY-777")
REQUIRE_API_KEY=os.getenv("REQUIRE_API_KEY","true").lower() in ("1","true","yes","y")
CORS_ORIGINS=os.getenv("CORS_ORIGINS","*")
PORT=int(os.getenv("PORT","5000"))
MAX_CHARS=int(os.getenv("MAX_CHARS","800"))
RATE_LIMIT_PER_MIN=int(os.getenv("RATE_LIMIT_PER_MIN","30"))
DEFAULT_VOICE=os.getenv("DEFAULT_VOICE","en-NG-EzinneNeural")
DEFAULT_VOICE_ALT=os.getenv("DEFAULT_VOICE_ALT","en-NG-AbeoNeural")
FILTER_NG=os.getenv("FILTER_NG","true").lower() in ("1","true","yes","y")

FORMAT_MAP={
    "mp3_48k":"audio-24khz-48kbitrate-mono-mp3",
    "mp3_96k":"audio-24khz-96kbitrate-mono-mp3",
    "mp3_24k":"audio-24khz-24kbitrate-mono-mp3",
    "wav_16k":"riff-16khz-16bit-mono-pcm",
    "wav_24k":"riff-24khz-16bit-mono-pcm",
}
DEFAULT_FORMAT=os.getenv("OUTPUT_FORMAT","mp3_48k")
if DEFAULT_FORMAT not in FORMAT_MAP: DEFAULT_FORMAT="mp3_48k"

app=Flask(__name__)
CORS(app, origins=CORS_ORIGINS if CORS_ORIGINS!="*" else "*")

_bucket: Dict[str, list]= {}

def _client_ip()->str:
    xf=request.headers.get("x-forwarded-for","").split(",")[0].strip()
    return xf or request.remote_addr or "unknown"

def _ok_key()->bool:
    if not REQUIRE_API_KEY: return True
    supplied = request.headers.get("x-api-key") or request.args.get("api_key")
    return supplied == API_KEY

def _limit()->bool:
    ip=_client_ip(); now=time.time(); q=_bucket.setdefault(ip,[])
    cutoff=now-60.0
    while q and q[0] < cutoff: q.pop(0)
    if len(q) >= RATE_LIMIT_PER_MIN: return False
    q.append(now); return True

def _bad(msg:str, code:int=400):
    return jsonify({"ok":False, "error":msg}), code

async def synthesize_to_bytes(text:str, voice:str, output_key:str, rate:str=None, volume:str=None, pitch:str=None)->bytes:
    kwargs={"voice":voice, "text":text, "output_format":FORMAT_MAP[output_key]}
    if rate: kwargs["rate"]=rate
    if volume: kwargs["volume"]=volume
    if pitch: kwargs["pitch"]=pitch
    tmp=None
    try:
        tmp=tempfile.NamedTemporaryFile(suffix=".audio", delete=False)
        tmp.close()
        comm=edge_tts.Communicate(**kwargs)
        await comm.save(tmp.name)
        with open(tmp.name,"rb") as f:
            data=f.read()
        return data
    finally:
        if tmp and os.path.exists(tmp.name):
            try: os.remove(tmp.name)
            except Exception: pass

def run_async(coro):
    try: loop=asyncio.get_event_loop()
    except RuntimeError:
        loop=asyncio.new_event_loop(); asyncio.set_event_loop(loop)
    if loop.is_running():
        new=asyncio.new_event_loop()
        try: return new.run_until_complete(coro)
        finally: new.close()
    else:
        return loop.run_until_complete(coro)

@app.get("/health")
def health():
    # lightweight health for bootstrapping; voice fetch is best-effort
    try:
        voices = run_async(edge_tts.list_voices())
        sample = [v for v in voices if (not FILTER_NG) or v.get("Locale","").endswith("NG")]
        h=hashlib.sha1(json.dumps(sample[:5], sort_keys=True).encode()).hexdigest()
        return jsonify({"ok":True,"voices":len(voices),"ng_voices":len(sample),"hash":h})
    except Exception:
        return jsonify({"ok":True,"voices":0,"ng_voices":0,"hash":"degraded"})

@app.get("/voices")
def voices():
    try:
        voices=run_async(edge_tts.list_voices())
        if FILTER_NG:
            voices=[v for v in voices if v.get("Locale","").endswith("NG")]
        return jsonify({"ok":True,"voices":voices})
    except Exception as e:
        return _bad(f"voice_list_failed: {e}", 500)

@app.post("/api/speak")
def speak():
    if not _ok_key(): return _bad("unauthorized", 401)
    if not _limit(): return _bad("rate_limited", 429)
    try:
        payload=request.get_json(force=True,silent=False) or {}
    except Exception:
        payload={}
    text=(payload.get("text") or "").strip()
    if not text: return _bad("text is required")
    if len(text) > MAX_CHARS: return _bad(f"text too long (>{MAX_CHARS} chars).")
    voice=payload.get("voice") or DEFAULT_VOICE
    if voice.lower()=="male": voice=DEFAULT_VOICE_ALT
    if voice.lower()=="female": voice=DEFAULT_VOICE
    fmt=payload.get("format") or DEFAULT_FORMAT
    if fmt not in FORMAT_MAP: return _bad("invalid format")
    rate=payload.get("rate"); volume=payload.get("volume"); pitch=payload.get("pitch")
    data=run_async(synthesize_to_bytes(text, voice, fmt, rate, volume, pitch))
    mime="audio/mpeg" if fmt.startswith("mp3") else "audio/wav"
    filename=f"speech.{ 'mp3' if mime=='audio/mpeg' else 'wav' }"
    return send_file(io.BytesIO(data), mimetype=mime, as_attachment=True, download_name=filename)

@app.get("/docs")
def docs():
    return Response(f"""<!DOCTYPE html><html><head><meta charset="utf-8"><title>ODIADEV Edge-TTS</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
body{{font-family:system-ui,Segoe UI,Arial,sans-serif;margin:40px;color:#0a0a0a;}}
.card{{max-width:860px;margin:auto;padding:24px;border-radius:18px;box-shadow:0 8px 24px rgba(2,6,23,.08);border:1px solid #e5e7eb;}}
h1{{font-size:26px;margin:0 0 12px}} label{{display:block;margin-top:12px;font-weight:600}}
select,input,textarea{{width:100%;padding:10px;border:1px solid #d1d5db;border-radius:12px}}
button{{margin-top:16px;padding:12px 18px;border:0;border-radius:12px;background:#111827;color:#fff;cursor:pointer}}
small{{color:#4b5563}} .badge{{display:inline-block;background:#111827;color:#fff;padding:2px 8px;border-radius:999px;font-size:12px;margin-left:8px}}
footer{{margin-top:12px;color:#6b7280}}
</style></head><body>
<div class="card">
  <h1>ODIADEV TTS <span class="badge">Edge</span></h1>
  <p>Self-hosted wrapper around Microsoft Edge voices. Nigeria-first defaults.</p>
  <label>API Key <small>(X-API-Key)</small></label>
  <input id="k" placeholder="ODIADEV-KEY-777" value="{API_KEY if not REQUIRE_API_KEY else ''}">
  <label>Text</label>
  <textarea id="t" rows="4">Welcome to ODIADEV.</textarea>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
    <div><label>Voice</label><select id="v"></select></div>
    <div><label>Format</label>
      <select id="f">
        <option value="mp3_48k" selected>MP3 48kbps</option>
        <option value="mp3_96k">MP3 96kbps</option>
        <option value="mp3_24k">MP3 24kbps</option>
        <option value="wav_16k">WAV 16kHz</option>
        <option value="wav_24k">WAV 24kHz</option>
      </select>
    </div>
  </div>
  <button onclick="speak()">Synthesize</button>
  <audio id="a" style="margin-top:16px;width:100%" controls></audio>
  <footer>Health: <span id="h">checking</span></footer>
</div>
<script>
async function loadVoices(){ const res=await fetch('/voices'); const js=await res.json();
 const sel=document.getElementById('v'); sel.innerHTML='';
 (js.voices||[]).forEach(v=>{ const o=document.createElement('option'); o.value=v.ShortName; o.text=`${v.ShortName} (${v.Locale})`; sel.appendChild(o); }); }
async function speak(){ const k=document.getElementById('k').value; const text=document.getElementById('t').value;
 const voice=document.getElementById('v').value; const format=document.getElementById('f').value;
 const res=await fetch('/api/speak',{method:'POST',headers:{'Content-Type':'application/json','X-API-Key':k},body:JSON.stringify({text,voice,format})});
 if(!res.ok){ const t=await res.text(); alert('Error: '+t); return; }
 const blob=await res.blob(); const url=URL.createObjectURL(blob); document.getElementById('a').src=url; }
async function health(){ try{ const r=await fetch('/health'); const j=await r.json(); document.getElementById('h').innerText=j.ok?`OK (voices: ${j.voices}, NG: ${j.ng_voices})`:('ERR'); }catch(e){document.getElementById('h').innerText='ERR';}}
loadVoices(); health();
</script></body></html>""", mimetype="text/html")

@app.get("/")
def root():
    return jsonify({"ok":True,"message":"ODIADEV Edge-TTS API","docs":"/docs","health":"/health"})

if __name__ == "__main__":
    print(f"ODIADEV Edge-TTS starting on 0.0.0.0:{PORT} ...")
    app.run(host="0.0.0.0", port=PORT, debug=False)
PY

sudo tee "$APP_DIR/requirements.txt" >/dev/null <<'REQ'
Flask==3.0.3
flask-cors==4.0.1
edge-tts==6.1.10
gunicorn==22.0.0
requests==2.32.3
REQ

sudo tee "$APP_DIR/gunicorn.conf.py" >/dev/null <<'GC'
bind = "0.0.0.0:8080"
workers = 2
worker_class = "gthread"
threads = 8
timeout = 60
graceful_timeout = 30
keepalive = 5
accesslog = "-"
errorlog = "-"
GC

# --------- python venv & deps ---------
sudo -u "$SERVICE_USER" $PY_BIN -m venv "$APP_DIR/venv"
sudo -u "$SERVICE_USER" "$APP_DIR/venv/bin/pip" install --upgrade pip wheel
sudo -u "$SERVICE_USER" "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

# --------- env file (locked) ---------
API_KEY_VALUE="${API_KEY:-ODIADEV-KEY-777}"
REQUIRE_VALUE="${REQUIRE_API_KEY:-true}"
sudo tee "$ENV_FILE" >/dev/null <<EOF
API_KEY=$API_KEY_VALUE
REQUIRE_API_KEY=$REQUIRE_VALUE
PORT=$PORT
CORS_ORIGINS=*
OUTPUT_FORMAT=mp3_48k
FILTER_NG=true
MAX_CHARS=800
RATE_LIMIT_PER_MIN=30
EOF
sudo chmod 600 "$ENV_FILE"

# --------- systemd service ---------
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<SVC
[Unit]
Description=ODIADEV Edge-TTS (Flask+Gunicorn)
After=network.target

[Service]
Type=simple
EnvironmentFile=$ENV_FILE
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/gunicorn -c gunicorn.conf.py app:app
User=$SERVICE_USER
Group=$SERVICE_USER
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SVC

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME" --now

# --------- nginx site ---------
sudo tee "$NGINX_SITE" >/dev/null <<'NGX'
server {
    listen 80 default_server;
    server_name _;
    client_max_body_size 4M;

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 65;
    }
}
NGX

sudo nginx -t
sudo systemctl restart nginx

# --------- smoke tests ---------
set +e
curl -sSf http://127.0.0.1/ | grep -q '"ok":true'
ROOT_OK=$?
if [ $ROOT_OK -ne 0 ]; then
  echo "Boot check failed: API root not responding"; journalctl -u "$SERVICE_NAME" --no-pager -n 50; exit 1
fi

TMP=/tmp/odiadev-tts-test.mp3
curl -s -X POST "http://127.0.0.1/api/speak" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY_VALUE}" \
  -d '{"text":"Hello from ODIADEV Edge TTS in Lagos","voice":"en-NG-EzinneNeural"}' --output "$TMP"
if [ ! -s "$TMP" ]; then
  echo "NOTE: TTS smoke did not produce audio (upstream may be slow). Service is up. Check later: http://<EC2-IP>/docs"
else
  echo "TTS smoke OK -> $TMP"
fi
set -e

echo "$API_KEY_VALUE" | sudo tee /root/odiadev-edge-tts-api-key.txt >/dev/null
echo "DONE. Open http://<EC2-IP>/docs    API key saved at /root/odiadev-edge-tts-api-key.txt"
