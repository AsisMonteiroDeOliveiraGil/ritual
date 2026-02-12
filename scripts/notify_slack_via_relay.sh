#!/usr/bin/env bash
set -euo pipefail

# Ir a raíz del repo
if ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$ROOT_DIR"
else
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || pwd)"
  cd "$ROOT_DIR"
fi

# Comprobar entorno
if [[ -z "${SLACK_RELAY_URL:-}" || -z "${SLACK_RELAY_SECRET:-}" ]]; then
  echo "Faltan variables SLACK_RELAY_URL y/o SLACK_RELAY_SECRET" >&2
  exit 2
fi

# Inputs opcionales: STATUS (0/!=0) y TAIL_MSG o ruta OUTPUT_FILE
STATUS="${1:-0}"
SECOND_ARG="${2:-}"
TAIL_MSG=""
OUTPUT_FILE=""
if [[ -n "$SECOND_ARG" && -f "$SECOND_ARG" ]]; then
  OUTPUT_FILE="$SECOND_ARG"
else
  TAIL_MSG="$SECOND_ARG"
fi

# Determinar versión
if [[ -f lib/core/constants/app_version.dart ]]; then
  VERSION=$(sed -n "s/.*kAppVersion\s*=\s*'\([^']*\)'.*/\1/p" lib/core/constants/app_version.dart | head -n1)
  VERSION=${VERSION:-unknown}
else
  VERSION="unknown"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
ACTOR=$(git config user.name 2>/dev/null || echo "Codex")

# Cargar resumen (primeras 10 líneas) y luego borrar el archivo
SUMMARY_FILE=".codex_summary.txt"
if [[ -f "$SUMMARY_FILE" ]]; then
  TASK_SUMMARY_RAW=$(head -n 10 "$SUMMARY_FILE")
  SUMMARY_OK=$(grep -E "^✅" "$SUMMARY_FILE" || true)
  SUMMARY_ERR=$(grep -E "^❌" "$SUMMARY_FILE" || true)
  # Derivar pedido breve de la primera línea (sin emojis/markdown), o usar env
  if [[ -z "${CODEX_TASK_BRIEF:-}" ]]; then
    TASK_BRIEF=$(head -n 1 "$SUMMARY_FILE" | sed -E 's/^[✅❌\-\*\s]+//; s/`//g; s/\*//g; s/^\s+|\s+$//g')
  else
    TASK_BRIEF="$CODEX_TASK_BRIEF"
  fi
  rm -f "$SUMMARY_FILE"
else
  TASK_SUMMARY_RAW=$(git log -1 --pretty=format:"%s" 2>/dev/null || echo "Actualización automática vía Codex")
  SUMMARY_OK=""
  SUMMARY_ERR=""
  TASK_BRIEF="${CODEX_TASK_BRIEF:-}"
fi

# Preparar tail/errores si se pasó OUTPUT_FILE
ERROR_SNIPPET=""
if [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]]; then
  TAIL_MSG=$(tail -n 20 "$OUTPUT_FILE" | sed 's/`/\\`/g')
  if [[ "$STATUS" != "0" ]]; then
    # Selección inteligente del primer bloque de error relevante con contexto
    # Prioridad de patrones comunes en Flutter/Dart/Firebase
    declare -a PATTERNS=(
      'Unhandled exception'
      '^Exception:'
      '^Error:'
      'Build failed in'
      'Command PhaseScriptExecution failed'
      'Target kernel_snapshot failed'
      'FAILURE: Build failed with an exception'
      '^lib/.+:[0-9]+:[0-9]+'
      '^web/.+:[0-9]+:[0-9]+'
      'FirebaseError|HTTP Error|Permission denied'
    )
    for P in "${PATTERNS[@]}"; do
      SNIP=$(awk -v IGNORECASE=1 -v pat="$P" -v ctx=8 '
        {
          line[NR]=$0
        }
        $0 ~ pat && start==0 {
          start = (NR>ctx)? NR-ctx : 1
          end = NR + ctx
        }
        END {
          if (start>0) {
            for (i=start; i<=end && i<=NR; i++) print line[i]
          }
        }
      ' "$OUTPUT_FILE" )
      if [[ -n "$SNIP" ]]; then
        ERROR_SNIPPET="$SNIP"
        break
      fi
    done
    # Fallback si no se encontró bloque
    if [[ -z "$ERROR_SNIPPET" ]]; then
      ERROR_SNIPPET=$(grep -iE "error|failed|exception|fatal" "$OUTPUT_FILE" | tail -n 10 || true)
    fi
    ERROR_SNIPPET=$(printf '%s' "$ERROR_SNIPPET" | sed 's/`/\\`/g')
  fi
fi
if [[ -z "$TAIL_MSG" ]]; then TAIL_MSG="Sin salida"; fi

# Duración opcional si se exporta START_TS
DURATION=""
if [[ -n "${START_TS:-}" ]]; then
  END_TS=$(date +%s)
  SECS=$(( END_TS - START_TS ))
  if (( SECS < 0 )); then SECS=0; fi
  DURATION=$(printf '%02d:%02d' $((SECS/60)) $((SECS%60)))
fi

TEXT_OK="<!here> :white_check_mark: Codex Web - v${VERSION} (éxito)"
TEXT_ERR="<!here> :x: Codex Web - v${VERSION} (fallo)"
TITLE_OK=":white_check_mark: Codex Web - v${VERSION}"
TITLE_ERR=":x: Codex Web - v${VERSION}"

if [[ "$STATUS" == "0" ]]; then
  TEXT="$TEXT_OK"; TITLE="$TITLE_OK"; COLOR="#36a64f"; EMOJI=":white_check_mark:"
else
  TEXT="$TEXT_ERR"; TITLE="$TITLE_ERR"; COLOR="#e01e5a"; EMOJI=":x:"
fi

# Montar payload
esc() { printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'; }
TS=$(date +%s)
PAYLOAD=$(cat <<JSON
{
  "text": "$(esc "$TEXT")",
  "attachments": [
    {
      "color": "${COLOR}",
      "title": "$(esc "$TITLE")",
      "fields": [
        $(
          [[ -n "$TASK_BRIEF" ]] && printf '{ "title": "🧾 Pedido", "value": "%s", "short": true },' "$(esc "$TASK_BRIEF")" || true
        )
        $(
          [[ -n "$DURATION" ]] && printf '{ "title": "⏱️ Duración", "value": "\"%s\"", "short": true },' "$DURATION" || true
        )
        { "title": "📝 Resumen", "value": "$(esc "$TASK_SUMMARY_RAW")", "short": false },
        $(
          [[ -n "$SUMMARY_OK" ]] && printf '{ "title": "✅ Éxitos", "value": "%s", "short": false },' "$(esc "$SUMMARY_OK")" || true
        )
        $(
          [[ -n "$SUMMARY_ERR" ]] && printf '{ "title": "❌ Fallos", "value": "%s", "short": false },' "$(esc "$SUMMARY_ERR")" || true
        )
        { "title": "📋 Salida del comando", "value": "$(esc "```$TAIL_MSG```")", "short": false }$(
          [[ -n "$ERROR_SNIPPET" ]] && printf ', { "title": "🧯 Errores detectados", "value": "%s", "short": false }' "$(esc "```$ERROR_SNIPPET```")" || true
        ),
        { "title": "🌐 Producción", "value": "<https://thefinalburgerapp.web.app/>", "short": false }
      ],
      "footer": "🍔 The Final Burger | Codex Automation",
      "footer_icon": "https://emojis.slackmojis.com/emojis/images/1643514389/10521/meow_code.gif",
      "ts": ${TS}
    }
  ]
}
JSON
)

# Enviar al relay
RESP_TMP=$(mktemp)
HTTP_CODE=$(curl -sS -w "%{http_code}" -o "$RESP_TMP" \
  -X POST "$SLACK_RELAY_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SLACK_RELAY_SECRET" \
  --data "$PAYLOAD" || true)

echo "HTTP_CODE=$HTTP_CODE"
cat "$RESP_TMP" || true
rm -f "$RESP_TMP"


