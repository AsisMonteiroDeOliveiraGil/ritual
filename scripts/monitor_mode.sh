#!/bin/bash

# Simple helper that prints the current mode depending on external monitors.
# - "Modo Monitor" when at least one external monitor is present.
# - "Modo Mac" when only the built-in display is available.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=monitor_detection.sh
source "${SCRIPT_DIR}/monitor_detection.sh"

DEBUG_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--debug|--verbose)
      DEBUG_MODE=1
      shift
      ;;
    *)
      echo "Uso: $(basename "$0") [--debug]" >&2
      exit 1
      ;;
  esac
done

if [[ "$DEBUG_MODE" -eq 1 ]]; then
  export MONITOR_DETECTION_DEBUG=1
  echo "[monitor_mode] Ejecutando en modo debug..." >&2
fi

monitor_count="$(detect_external_monitors)"

if [ -z "$monitor_count" ]; then
  monitor_count=0
fi

if [ "$monitor_count" -ge 1 ]; then
  echo "Modo Monitor"
  if [[ "$DEBUG_MODE" -eq 1 ]]; then
    echo "[monitor_mode] Monitores externos detectados: $monitor_count" >&2
  fi
else
  echo "Modo Mac"
  if [[ "$DEBUG_MODE" -eq 1 ]]; then
    echo "[monitor_mode] No se detectaron monitores externos" >&2
  else
    echo "No se detectaron monitores externos. Ejecuta '--debug' para más detalles." >&2
  fi
fi

