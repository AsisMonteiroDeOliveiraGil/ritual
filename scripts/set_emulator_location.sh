#!/bin/bash

# Script para configurar la ubicación GPS de los emuladores Android
# Uso: ./set_emulator_location.sh [latitud] [longitud]
# Ejemplo: ./set_emulator_location.sh 40.4929 -3.8737

set -euo pipefail

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
NC='\033[0m'

# Coordenadas por defecto: Calle Escalonia 15, Las Rozas de Madrid
DEFAULT_LATITUD=40.4929
DEFAULT_LONGITUD=-3.8737

# Usar coordenadas proporcionadas o las por defecto
LATITUD="${1:-$DEFAULT_LATITUD}"
LONGITUD="${2:-$DEFAULT_LONGITUD}"

echo -e "${BLUE}📍 Configurando ubicación GPS de emuladores...${NC}"
echo -e "${BLUE}📍 Dirección: Calle Escalonia 15, Las Rozas de Madrid${NC}"
echo -e "${BLUE}📍 Coordenadas: Latitud $LATITUD, Longitud $LONGITUD${NC}"
echo ""

# Verificar que adb esté disponible
if ! command -v adb >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  adb no está en PATH. Intentando agregar ruta común...${NC}"
  export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
  if ! command -v adb >/dev/null 2>&1; then
    echo -e "${YELLOW}❌ No se pudo encontrar adb. Por favor, asegúrate de que Android SDK esté instalado.${NC}"
    exit 1
  fi
fi

# Obtener lista de emuladores conectados
connected_devices=$(adb devices | grep 'emulator-' | awk '{print $1}')

if [ -z "$connected_devices" ]; then
  echo -e "${YELLOW}⚠️  No se encontraron emuladores activos${NC}"
  echo -e "${BLUE}💡 Inicia tus emuladores y vuelve a ejecutar este script${NC}"
  exit 1
fi

# Contar emuladores
emulator_count=$(echo "$connected_devices" | wc -l | xargs)
echo -e "${GREEN}✅ Encontrados $emulator_count emulador(es)${NC}"
echo ""

# Configurar ubicación en cada emulador
success_count=0
failed_count=0

while IFS= read -r device; do
  if [ -n "$device" ]; then
    echo -e "${BLUE}🔧 Configurando ubicación en $device...${NC}"
    
    # Usar adb emu geo fix para establecer la ubicación
    if adb -s "$device" emu geo fix "$LONGITUD" "$LATITUD" 2>/dev/null; then
      echo -e "${GREEN}  ✅ Ubicación configurada correctamente en $device${NC}"
      success_count=$((success_count + 1))
    else
      echo -e "${YELLOW}  ⚠️  No se pudo configurar la ubicación en $device (puede requerir reinicio del emulador)${NC}"
      failed_count=$((failed_count + 1))
    fi
  fi
done <<< "$connected_devices"

echo ""
if [ $success_count -gt 0 ]; then
  echo -e "${GREEN}✅ Ubicación configurada en $success_count emulador(es)${NC}"
fi
if [ $failed_count -gt 0 ]; then
  echo -e "${YELLOW}⚠️  $failed_count emulador(es) no pudieron ser configurados${NC}"
  echo -e "${BLUE}💡 Intenta reiniciar los emuladores y ejecutar el script nuevamente${NC}"
fi

echo ""
echo -e "${BLUE}📍 Ubicación configurada:${NC}"
echo -e "${BLUE}   Latitud: $LATITUD${NC}"
echo -e "${BLUE}   Longitud: $LONGITUD${NC}"
echo -e "${BLUE}   Dirección: Calle Escalonia 15, Las Rozas de Madrid${NC}"

