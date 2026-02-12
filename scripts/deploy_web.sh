#!/bin/bash

# Script para construir y desplegar automáticamente la aplicación web
# Uso: npm run dw

# Función helper para imprimir con lolcat si está disponible
lol_echo() {
    if command -v lolcat &> /dev/null; then
        echo "$@" | lolcat
    else
        echo "$@"
    fi
}

# Función para imprimir números grandes usando figlet con fuente big
# Nota: No aplica lolcat aquí porque se aplica externamente al bloque completo
print_big_version() {
    local version="$1"
    
    # Agregar espacios entre cada carácter: "v 1 . 0 . 6 1"
    local spaced_version="v"
    for (( i=0; i<${#version}; i++ )); do
        spaced_version="${spaced_version} ${version:$i:1}"
    done
    
    # Usar figlet con fuente big (igual que en delete_users.js)
    if command -v figlet &> /dev/null; then
        figlet -f big -w 200 "$spaced_version" 2>/dev/null || figlet -f big "$spaced_version" 2>/dev/null || echo "$spaced_version"
    else
        # Fallback si figlet no está disponible
        echo "$spaced_version"
    fi
}

lol_echo "🚀 Iniciando despliegue automático a la web..."

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    lol_echo "❌ Error: No se encontró pubspec.yaml. Ejecuta este script desde la raíz del proyecto."
    exit 1
fi

# Verificar que Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    lol_echo "❌ Error: Firebase CLI no está instalado. Instálalo con: npm install -g firebase-tools"
    exit 1
fi

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    lol_echo "❌ Error: Flutter no está instalado o no está en el PATH."
    exit 1
fi

lol_echo "✅ Verificaciones completadas"

# Actualizar versión de la aplicación
APP_VERSION_FILE="lib/core/constants/app_version.dart"
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
  lol_echo "❌ No se pudo actualizar la versión de la aplicación."
  exit 1
}

IFS=',' read -r PREVIOUS_VERSION NEW_VERSION <<< "$VERSION_RESULT"
export TFB_APP_VERSION="$NEW_VERSION"

lol_echo "🔢 Versión de la app actualizada: $PREVIOUS_VERSION -> $NEW_VERSION"
lol_echo "🚀 Preparando despliegue de la versión $NEW_VERSION..."

# Resolver credenciales de Firebase
if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    DEFAULT_SERVICE_ACCOUNT_PATH="$(pwd)/firebase-service-account.json"
    if [ -f "$DEFAULT_SERVICE_ACCOUNT_PATH" ]; then
        export GOOGLE_APPLICATION_CREDENTIALS="$DEFAULT_SERVICE_ACCOUNT_PATH"
        lol_echo "🔐 Usando credenciales del servicio Firebase ubicadas en firebase-service-account.json"
    else
        lol_echo "❌ Error: no se encontraron credenciales. Define GOOGLE_APPLICATION_CREDENTIALS o incluye firebase-service-account.json"
        exit 1
    fi
else
    lol_echo "🔐 Usando credenciales definidas por GOOGLE_APPLICATION_CREDENTIALS"
fi

FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-thefinalburgerapp}"

# Ejecutar el script de build existente
lol_echo "🔧 Ejecutando build de la aplicación web..."
chmod +x scripts/build_web.sh
./scripts/build_web.sh

# Verificar que el build fue exitoso
if [ $? -ne 0 ]; then
    lol_echo "❌ Error en el build. Abortando despliegue."
    exit 1
fi

lol_echo "✅ Build completado exitosamente"

# Desplegar a Firebase
FIREBASE_ARGS=(--project "$FIREBASE_PROJECT_ID" --non-interactive)

# Verificar autenticación antes de desplegar
lol_echo "🔐 Verificando autenticación de Firebase..."
if firebase projects:list --non-interactive &>/dev/null; then
    lol_echo "✅ Firebase CLI autenticado correctamente con cuenta de servicio"
else
    lol_echo "❌ Error: Firebase CLI no está autenticado."
    lol_echo "💡 Asegúrate de que GOOGLE_APPLICATION_CREDENTIALS esté configurado con la cuenta de servicio"
    exit 1
fi

lol_echo "🌐 Desplegando a Firebase Hosting..."
if firebase deploy --only hosting "${FIREBASE_ARGS[@]}"; then
    lol_echo ""
    lol_echo "🎉 ¡Despliegue completado exitosamente!"
    lol_echo "🌐 Tu aplicación está disponible en: https://thefinalburgerapp.web.app"
    lol_echo "📊 Consola de Firebase: https://console.firebase.google.com/project/thefinalburgerapp/overview"
    if [ -n "${TFB_APP_VERSION:-}" ]; then
        lol_echo "🔢 Versión desplegada: ${TFB_APP_VERSION}"
        lol_echo "🍔 Se ha desplegado v${TFB_APP_VERSION} 🔥🚀"
        lol_echo "⚡ ¡Tu app está en llamas! (literalmente con Firebase 🔥)"
        
        # Enviar notificaciones
        lol_echo ""
        lol_echo "📢 Enviando notificaciones..."
        
        # Verificar que Node.js está instalado
        if ! command -v node &> /dev/null; then
            lol_echo "⚠️ Node.js no está instalado. Saltando envío de notificaciones."
        else
            # Enviar notificación de despliegue Codex web
            if [ -f "scripts/send_release_notification.js" ]; then
                lol_echo "📣 Enviando notificación de despliegue Codex web..."
                if node scripts/send_release_notification.js "$TFB_APP_VERSION"; then
                    lol_echo "✅ Notificación de despliegue enviada correctamente"
                else
                    lol_echo "⚠️ No se pudo enviar la notificación de despliegue"
                fi
            else
                lol_echo "⚠️ Script de notificación no encontrado"
            fi
        fi
        
        # Imprimir versión grande al final de todo
        lol_echo ""
        lol_echo "═══════════════════════════════════════════════════════════════"
        lol_echo ""
        lol_echo "                      v${TFB_APP_VERSION}"
        lol_echo ""
        print_big_version "${TFB_APP_VERSION}" | (
            if command -v lolcat &> /dev/null; then
                lolcat
            else
                cat
            fi
        )
        lol_echo ""
        lol_echo "═══════════════════════════════════════════════════════════════"
    fi
else
    lol_echo "❌ Error en el despliegue"
    exit 1
fi
