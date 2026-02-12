#!/usr/bin/env bash
set -euo pipefail

# Ubicar raíz del repo de forma robusta
if ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$ROOT_DIR"
else
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || pwd)"
  cd "$ROOT_DIR"
fi

# Parámetros opcionales
SUMMARY_DEFAULT="✅ Prueba manual de notificación Slack desde script (sin build)"
TAIL_DEFAULT="[TEST] Salida ficticia de dwc para prueba manual de Slack"
SUMMARY="${1:-$SUMMARY_DEFAULT}"
TAIL_MSG="${2:-$TAIL_DEFAULT}"

# Datos de contexto
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Extraer versión sin usar grep -P (compatibilidad macOS)
if [[ -f lib/core/constants/app_version.dart ]]; then
  VERSION=$(sed -n "s/.*kAppVersion\s*=\s*'\([^']*\)'.*/\1/p" lib/core/constants/app_version.dart | head -n1)
  VERSION=${VERSION:-unknown}
else
  VERSION="unknown"
fi

# Construir payload JSON (similar a codex.yaml)
PAYLOAD=$(cat <<JSON
{
  "text": ":white_check_mark: Codex Web - v${VERSION} (éxito)",
  "attachments": [
    {
      "color": "#36a64f",
      "title": ":white_check_mark: Codex Web - v${VERSION}",
      "fields": [
        { "title": "📝", "value": "${SUMMARY}", "short": false },
        { "title": "Rama", "value": "\`${BRANCH}\`", "short": true },
        { "title": "📋 Salida del comando", "value": "```${TAIL_MSG}```", "short": false }
      ],
      "footer": "🍔 The Final Burger | Codex Automation",
      "footer_icon": "https://emojis.slackmojis.com/emojis/images/1643514389/10521/meow_code.gif",
      "ts": $(date +%s)
    }
  ]
}
JSON
)

# Enviar a Slack (webhook tomado de variable de entorno)
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

RESP_TMP=$(mktemp)
HTTP_CODE=$(curl -sS -w "%{http_code}" -o "$RESP_TMP" \
  -X POST -H "Content-type: application/json" \
  --data "$PAYLOAD" "$WEBHOOK_URL" || true)

echo "HTTP_CODE=$HTTP_CODE"
if [[ "$HTTP_CODE" =~ ^2 ]]; then
  echo "✅ Notificación enviada correctamente"
else
  echo "⚠️ Error al enviar notificación a Slack"
  echo "Respuesta: $(cat "$RESP_TMP")"
fi

rm -f "$RESP_TMP"

# Mensaje final de ayuda
echo "Usos:" >&2
echo "  scripts/test_codex_slack.sh" >&2
echo "  scripts/test_codex_slack.sh \"Mensaje resumen\" \"Texto salida comando\"" >&2
