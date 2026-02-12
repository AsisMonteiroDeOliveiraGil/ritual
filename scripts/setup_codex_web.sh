#!/usr/bin/env bash
# Script de configuración automática para Codex Web
# Configura todo automáticamente usando la cuenta de servicio

set -euo pipefail

echo "🔧 Configurando entorno automáticamente para Codex Web..."

ROOT_DIR="$(pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/.codex_cache"
mkdir -p "$BOOTSTRAP_DIR"

DESIRED_FLUTTER_VERSION="${FLUTTER_VERSION_OVERRIDE:-3.35.7}"

ensure_setup_script() {
  local script_path="$1"
  if [ ! -x "$script_path" ]; then
    chmod +x "$script_path"
  fi
}

detect_flutter_version() {
  if ! command -v flutter >/dev/null 2>&1; then
    return 1
  fi

  local version_line
  version_line="$(flutter --version 2>/dev/null | head -n 1)"
  if [[ "$version_line" =~ Flutter[[:space:]]([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

ensure_flutter() {
  local required_version="$1"
  local current_version=""

  if command -v flutter >/dev/null 2>&1; then
    current_version="$(detect_flutter_version || true)"
  fi

  if [ -n "$current_version" ] && [ "$current_version" = "$required_version" ]; then
    echo "✅ Flutter ${current_version} ya está instalado."
  else
    if [ -n "$current_version" ]; then
      echo "⚠️ Se detectó Flutter ${current_version}, se reinstalará la versión requerida ${required_version}."
    else
      echo "❌ Flutter no está instalado en este entorno."
    fi

    local bootstrap_script="$ROOT_DIR/scripts/setup_web_environment.sh"
    ensure_setup_script "$bootstrap_script"

    echo "⚙️ Ejecutando bootstrap automático de Flutter ${required_version}..."
    if ! FLUTTER_VERSION="$required_version" "$bootstrap_script"; then
      echo "❌ Error durante la instalación automática de Flutter."
      exit 1
    fi

    echo "⚙️ Configurando soporte web de Flutter..."
    flutter config --enable-web >/dev/null 2>&1 || true
    flutter precache --web

    current_version="$(detect_flutter_version || true)"
    if [ "$current_version" != "$required_version" ]; then
      echo "❌ No se pudo verificar la versión de Flutter instalada."
      exit 1
    fi
  fi

  echo "🩺 Ejecutando flutter doctor para validar la instalación..."
  flutter doctor -v | tee "$BOOTSTRAP_DIR/flutter_doctor.log" >/dev/null
}

# Configurar automáticamente las credenciales de la cuenta de servicio
SERVICE_ACCOUNT_PATH="${ROOT_DIR}/firebase-service-account.json"
if [ -f "$SERVICE_ACCOUNT_PATH" ]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$SERVICE_ACCOUNT_PATH"
    echo "✅ Usando cuenta de servicio: $SERVICE_ACCOUNT_PATH"
else
    echo "❌ Error: No se encontró firebase-service-account.json"
    echo "💡 Asegúrate de que el archivo existe en la raíz del proyecto"
    exit 1
fi

ensure_flutter "$DESIRED_FLUTTER_VERSION"

# Verificar Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "⚠️ Firebase CLI no encontrado. Instalando..."
    npm install -g firebase-tools
else
    echo "✅ Firebase CLI ya está instalado: $(firebase --version)"
fi

echo ""
echo "🔐 Verificando autenticación con cuenta de servicio..."
if firebase projects:list --non-interactive &>/dev/null; then
    echo "✅ Autenticación exitosa con cuenta de servicio"
else
    echo "❌ Error: La cuenta de servicio no tiene permisos suficientes"
    echo "💡 Asegúrate de que la cuenta de servicio tenga los roles:"
    echo "   - Firebase Admin"
    echo "   - Editor (mínimo)"
    exit 1
fi

echo ""
echo "✅ Entorno listo. Ahora puedes ejecutar: npm run dwc"
