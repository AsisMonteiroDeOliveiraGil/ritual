#!/bin/bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Uso: npm run menu -- <nombre_de_la_imagen>"
  exit 1
fi

IMAGE_NAME="$1"
DESKTOP_IMAGE="$HOME/Desktop/${IMAGE_NAME}"

if [[ ! -f "${DESKTOP_IMAGE}" ]]; then
  echo "No se encontró el archivo en: ${DESKTOP_IMAGE}"
  exit 1
fi

chmod +x "$(dirname "$0")/add_menu_to_emulators.sh"
"$(dirname "$0")/add_menu_to_emulators.sh" "${DESKTOP_IMAGE}"

