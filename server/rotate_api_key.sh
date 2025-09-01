#!/usr/bin/env bash
# Rotate ODIADEV API key and restart service.
set -euo pipefail
SERVICE="odiadev-edge-tts"
ENV_FILE="/etc/${SERVICE}.env"
NEWKEY="${NEWKEY:-}"

if [ -z "$NEWKEY" ]; then
  NEWKEY="$(openssl rand -base64 24 | tr -d '=+/')"
fi

sudo sed -i "s/^API_KEY=.*/API_KEY=${NEWKEY}/" "$ENV_FILE"
sudo systemctl restart "$SERVICE"
echo "New API key: ${NEWKEY}"
echo "$NEWKEY" | sudo tee /root/${SERVICE}-api-key.txt >/dev/null
