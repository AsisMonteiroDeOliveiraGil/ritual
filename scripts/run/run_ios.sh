#!/bin/bash

# Definición de colores
ORANGE='\033[38;5;208m'  # Un naranja más intenso y atractivo
NC='\033[0m' # No Color

# Exportar la API Key de Google Maps desde el .env (en la raíz del proyecto)
if [ -f .env ]; then
  export IOS_API_KEY=$(grep IOS_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  echo -e "${ORANGE}🔑 IOS_API_KEY exportada: ${IOS_API_KEY:0:10}...${NC}"
else
  echo -e "${ORANGE}⚠️  Archivo .env no encontrado en la raíz. No se exportó IOS_API_KEY.${NC}"
fi

# Buscar el simulador 'iPhone 16 Pro' que esté encendido (Booted)
BOOTED_ID=$(xcrun simctl list devices | grep 'iPhone 16 Pro' | grep Booted | grep -Eo '([A-F0-9\-]{36})')
if [ -z "$BOOTED_ID" ]; then
  echo -e "${ORANGE}❌ No hay ningún simulador 'iPhone 16 Pro' encendido (Booted). Por favor, inicia uno desde Xcode o con 'open -a Simulator'.${NC}"
  exit 1
fi

BOOTED_NAME="iPhone 16 Pro"

# Mostrar información del simulador seleccionado
echo -e "\n${ORANGE}📱 Simulador seleccionado: $BOOTED_NAME${NC}"
echo -e "${ORANGE}🆔 ID: $BOOTED_ID${NC}"

# Variable de control para el foco (solo una vez)
FOCUS_APPLIED=false

# Lanzando iOS
echo -e "\n${ORANGE}🍎 Lanzando en iOS ($BOOTED_NAME)${NC}\n"

flutter run -d $BOOTED_ID | while read line; do
  echo -e "${ORANGE}[iOS]${NC} $line"
  
  # Detectar cuando la app está a punto de abrirse y dar foco al simulador (SOLO UNA VEZ)
  if [[ "$FOCUS_APPLIED" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing app"* ]]); then
    echo -e "\n${ORANGE}🎯 Aplicación instalándose, dando foco al simulador...${NC}"
    
    # Marcar que ya se aplicó el foco
    FOCUS_APPLIED=true
    
    # Dar foco al simulador para que aparezca por encima de todas las aplicaciones
    open -a Simulator
    sleep 1
    osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true
    sleep 0.5
  fi
  
  # Detectar cuando la app está lista
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${ORANGE}✅ iOS listo: $BOOTED_NAME${NC}\n"
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${ORANGE}✅ iOS listo: $BOOTED_NAME${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${ORANGE}✅ iOS listo: $BOOTED_NAME${NC}\n"
  fi
done 