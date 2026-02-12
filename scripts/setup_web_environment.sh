#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.7}"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"
FLUTTER_INSTALL_PARENT="/opt"
FLUTTER_INSTALL_DIR="${FLUTTER_INSTALL_PARENT}/flutter"
BOOTSTRAP_SENTINEL="${FLUTTER_INSTALL_PARENT}/.tfb_flutter_bootstrap"

APT_PACKAGES=(
  adwaita-icon-theme
  at-spi2-common
  at-spi2-core
  clang
  cmake
  curl
  dbus-user-session
  dconf-gsettings-backend
  dconf-service
  gir1.2-atk-1.0
  gir1.2-atspi-2.0
  gir1.2-freedesktop
  gir1.2-freedesktop-dev
  gir1.2-gdkpixbuf-2.0
  gir1.2-glib-2.0-dev
  gir1.2-gtk-3.0
  gir1.2-harfbuzz-0.0
  gir1.2-pango-1.0
  git
  gsettings-desktop-schemas
  libatk-bridge2.0-dev
  libatk1.0-dev
  libatspi2.0-dev
  libcairo2-dev
  libclang-rt-18-dev
  libdatrie-dev
  libdbus-1-dev
  libdrm-dev
  libegl-dev
  libepoxy-dev
  libfribidi-dev
  libgdk-pixbuf-2.0-dev
  libglib2.0-dev
  libglu1-mesa
  libharfbuzz-dev
  liblzma-dev
  libmount-dev
  libpango1.0-dev
  libpixman-1-dev
  libstdc++-12-dev
  libwayland-dev
  libx11-dev
  libxcomposite-dev
  libxcursor-dev
  libxdamage-dev
  libxfixes-dev
  libxi-dev
  libxinerama-dev
  libxkbcommon-dev
  libxrandr-dev
  libxtst-dev
  mesa-utils
  ninja-build
  pkg-config
  tar
  unzip
  wget
  xz-utils
  zip
)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Error: $1 no está disponible en el PATH." >&2
    exit 1
  fi
}

SUDO=""
if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

run_cmd() {
  if [ -n "$SUDO" ]; then
    $SUDO "$@"
  else
    "$@"
  fi
}

update_and_install_apt_packages() {
  if [ -f "${BOOTSTRAP_SENTINEL}" ] && grep -qx "${FLUTTER_VERSION}" "${BOOTSTRAP_SENTINEL}"; then
    echo "📦 Dependencias de sistema ya instaladas para Flutter ${FLUTTER_VERSION}."
    return
  fi

  echo "📦 Instalando dependencias de sistema necesarias para Flutter ${FLUTTER_VERSION}..."
  run_cmd apt-get update
  run_cmd apt-get install -y "${APT_PACKAGES[@]}"
}

install_flutter() {
  if [ -d "${FLUTTER_INSTALL_DIR}" ]; then
    echo "🔁 Eliminando instalación anterior de Flutter para garantizar la versión solicitada..."
    run_cmd rm -rf "${FLUTTER_INSTALL_DIR}" || true
  fi

  echo "⬇️ Descargando Flutter ${FLUTTER_VERSION}..."
  run_cmd mkdir -p "${FLUTTER_INSTALL_PARENT}"
  pushd "${FLUTTER_INSTALL_PARENT}" >/dev/null
  run_cmd rm -f "${FLUTTER_ARCHIVE}"
  run_cmd wget -q "${FLUTTER_URL}"
  echo "📦 Extrayendo Flutter..."
  run_cmd tar xf "${FLUTTER_ARCHIVE}"
  run_cmd rm -f "${FLUTTER_ARCHIVE}"
  popd >/dev/null

  echo "🔗 Configurando accesos directos del binario..."
  run_cmd ln -sf "${FLUTTER_INSTALL_DIR}/bin/flutter" /usr/local/bin/flutter
  run_cmd ln -sf "${FLUTTER_INSTALL_DIR}/bin/dart" /usr/local/bin/dart

  echo "${FLUTTER_VERSION}" | run_cmd tee "${BOOTSTRAP_SENTINEL}" >/dev/null

  if command -v git >/dev/null 2>&1; then
    git config --global --add safe.directory "${FLUTTER_INSTALL_DIR}" || true
  fi

  echo "🧪 Verificando instalación de Flutter..."
  flutter --version
}

install_firebase_cli() {
  require_command npm
  echo "☁️ Instalando Firebase CLI de forma global..."
  if [ -n "$SUDO" ]; then
    $SUDO env npm_config_progress=false npm_config_loglevel=error npm install -g firebase-tools
  else
    npm_config_progress=false npm_config_loglevel=error npm install -g firebase-tools
  fi
  echo "🧪 Verificando instalación de Firebase CLI..."
  firebase --version
}

main() {
  update_and_install_apt_packages
  install_flutter
  install_firebase_cli
  echo "🎉 Entorno listo para ejecutar 'npm run dw'."
}

main "$@"
