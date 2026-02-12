#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Preferir el nuevo setup global si existe para evitar duplicidad
NEW_SETUP_SCRIPT="$ROOT_DIR/codex_setup.sh"
CODEUX_SETUP_SCRIPT="$ROOT_DIR/scripts/setup_codex_web.sh"
DEPLOY_SCRIPT="$ROOT_DIR/scripts/deploy_web.sh"
APP_VERSION_FILE="$ROOT_DIR/lib/core/constants/app_version.dart"
RELEASE_NOTIFICATION_SCRIPT="$ROOT_DIR/scripts/send_release_notification.js"

cd "$ROOT_DIR"

echo "🧰 Preparando entorno para build y deploy web..."

# Configurar automáticamente las credenciales de la cuenta de servicio
SERVICE_ACCOUNT_PATH="$ROOT_DIR/firebase-service-account.json"
if [ -f "$SERVICE_ACCOUNT_PATH" ]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_PATH"
    echo "✅ Usando cuenta de servicio: $SERVICE_ACCOUNT_PATH"
else
    echo "❌ Error: No se encontró firebase-service-account.json"
    exit 1
fi

# Ejecutar el setup (nuevo si existe, si no el anterior)
if [ -f "$NEW_SETUP_SCRIPT" ]; then
  if [ ! -x "$NEW_SETUP_SCRIPT" ]; then
    chmod +x "$NEW_SETUP_SCRIPT"
  fi
  # Importar el script para propagar PATH y variables al shell actual
  # shellcheck disable=SC1090
  . "$NEW_SETUP_SCRIPT"
else
  if [ ! -x "$CODEUX_SETUP_SCRIPT" ]; then
    chmod +x "$CODEUX_SETUP_SCRIPT"
  fi
  # Importar el script legacy para propagar PATH y variables al shell actual
  # shellcheck disable=SC1090
  . "$CODEUX_SETUP_SCRIPT"
fi

echo "✅ Entorno listo. Continuando con build y deploy..."

if [ ! -f "$APP_VERSION_FILE" ]; then
  cat <<'EOF' > "$APP_VERSION_FILE"
/// Current application version displayed in the profile screen and updated by
/// deployment scripts before each release.
const String kAppVersion = '1.0.0';
EOF
fi

VERSION_RESULT=$(APP_VERSION_FILE="$APP_VERSION_FILE" python3 - <<'PY'
from pathlib import Path
import os
import re
import sys

path = Path(os.environ['APP_VERSION_FILE'])
text = path.read_text()
match = re.search(r"kAppVersion\s*=\s*'(\d+)\.(\d+)\.(\d+)'", text)
if not match:
    sys.exit("parse_error")
major, minor, patch = map(int, match.groups())
old_version = f"{major}.{minor}.{patch}"
new_version = f"{major}.{minor}.{patch + 1}"
updated = re.sub(
    r"kAppVersion\s*=\s*'(\d+\.\d+\.\d+)'",
    f"kAppVersion = '{new_version}'",
    text,
    count=1,
)
path.write_text(updated)
print(f"{old_version},{new_version}")
PY
) || {
  echo "❌ No se pudo actualizar la versión de la aplicación."
  exit 1
}

IFS=',' read -r PREVIOUS_VERSION NEW_VERSION <<< "$VERSION_RESULT"
export TFB_APP_VERSION="$NEW_VERSION"

echo "🔢 Versión de la app actualizada: $PREVIOUS_VERSION -> $NEW_VERSION"
echo "🚀 Preparando despliegue de la versión $NEW_VERSION..."

if [ ! -x "$DEPLOY_SCRIPT" ]; then
  chmod +x "$DEPLOY_SCRIPT"
fi
"$DEPLOY_SCRIPT"

echo "📢 Notificaciones de deploy"

# Para evitar duplicados con codex:notify, la notificación de release está
# desactivada por defecto. Se puede reactivar exportando TFB_ENABLE_RELEASE_NOTIFY=1
if [ "${TFB_ENABLE_RELEASE_NOTIFY:-}" = "1" ]; then
  # Verificar que Node.js está instalado
  if ! command -v node &> /dev/null; then
      echo "⚠️ Node.js no está instalado. Saltando envío de notificaciones."
  else
      # Enviar notificación de despliegue Codex web
      if [ -f "$RELEASE_NOTIFICATION_SCRIPT" ]; then
          echo "📣 Enviando notificación de despliegue Codex web..."
          if node "$RELEASE_NOTIFICATION_SCRIPT" "$NEW_VERSION"; then
              echo "✅ Notificación de despliegue enviada correctamente"
          else
              echo "⚠️ No se pudo enviar la notificación de despliegue"
          fi
      else
          echo "⚠️ Script de notificación no encontrado: $RELEASE_NOTIFICATION_SCRIPT"
      fi
  fi
else
  echo "ℹ️ Notificación de release desactivada (usar TFB_ENABLE_RELEASE_NOTIFY=1 para habilitar)."
fi

echo "✅ Proceso completado para la versión $NEW_VERSION"
