#!/bin/bash

# Variables booleanas para controlar qué dispositivos lanzar
LAUNCH_IOS=true
LAUNCH_PIXEL_9=true
LAUNCH_PIXEL_9_2=false
LAUNCH_WEB=true

# Definición de colores
GREEN='\033[38;5;46m'  # Verde intenso para Android
ORANGE='\033[38;5;208m'  # Naranja intenso para iOS
BLUE='\033[38;5;39m'  # Azul brillante para Web
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Mostrar configuración de dispositivos
echo -e "${YELLOW}📱 Configuración de dispositivos:${NC}"
echo -e "  iOS: ${LAUNCH_IOS}${NC}"
echo -e "  Pixel 9: ${LAUNCH_PIXEL_9}${NC}"
echo -e "  Pixel 9 (2): ${LAUNCH_PIXEL_9_2}${NC}"
echo -e "  Web: ${LAUNCH_WEB}${NC}"
echo ""

# Exportar las API Keys de Google Maps desde el .env (en la raíz del proyecto)
if [ -f .env ]; then
  export ANDROID_API_KEY=$(grep ANDROID_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  export IOS_API_KEY=$(grep IOS_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  export WEB_API_KEY=$(grep WEB_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  export BACKEND_API_KEY=$(grep BACKEND_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  # echo -e "${GREEN}🔑 ANDROID_API_KEY exportada: ${ANDROID_API_KEY:0:10}...${NC}"
  # echo -e "${ORANGE}🔑 IOS_API_KEY exportada: ${IOS_API_KEY:0:10}...${NC}"
  # echo -e "${BLUE}🔑 WEB_API_KEY exportada: ${WEB_API_KEY:0:10}...${NC}"
  # echo -e "${YELLOW}🔑 BACKEND_API_KEY exportada: ${BACKEND_API_KEY:0:10}...${NC}"
  echo -e "${GREEN}✅ API Keys exportadas correctamente${NC}"
else
  echo -e "${GREEN}⚠️  Archivo .env no encontrado en la raíz. No se exportaron las API Keys.${NC}"
fi

# Definir el identificador del simulador iPhone 16 Pro
ios_device_id="A8200FB9-3377-495B-BAA3-2EBCDB24169C"
# Definir el identificador del emulador Pixel 9
pixel9_device_id="emulator-5554"
# Definir el identificador del emulador Pixel 9 (2)
pixel9_2_device_id="pixel_9_arm64_2"

# Función para crear un marco decorativo
create_box() {
  local text="$1"
  local color="$2"
  local width=$(tput cols)

  # Calcular longitud visual aproximada
  local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
  local visual_length=${#clean_text}
  local padding=$(( (width - visual_length) / 2 ))
  local left_padding=$padding
  local right_padding=$(( width - visual_length - left_padding ))

  echo -e "${color}$(printf '─%.0s' $(seq 1 $width))${NC}"
  echo -e "$(printf ' %.0s' $(seq 1 $left_padding))${color}${text}${NC}$(printf ' %.0s' $(seq 1 $right_padding))"
  echo -e "${color}$(printf '─%.0s' $(seq 1 $width))${NC}"
}

# Función para dar foco al simulador de iOS
focus_ios_simulator() {
  echo -e "${ORANGE}🎯 Dando foco al simulador de iOS...${NC}"
  open -a Simulator
  sleep 1
  osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true
  sleep 0.5
}

# Función para dar foco al emulador de Android
focus_android_emulator() {
  echo -e "${GREEN}🎯 Dando foco al emulador de Android...${NC}"
  
  # Buscar y activar la ventana del emulador de Android
  if command -v wmctrl &> /dev/null; then
    # En sistemas Linux con wmctrl
    wmctrl -a "Android Emulator" 2>/dev/null || wmctrl -a "emulator" 2>/dev/null || true
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # En macOS, usar métodos más efectivos para dar foco al emulador
    
    # Método 1: Intentar activar por nombre de proceso
    echo -e "${GREEN}🔍 Buscando procesos del emulador de Android...${NC}"
    
    # Listar procesos relacionados con Android
    ps aux | grep -i "emulator\|qemu\|android" | grep -v grep || true
    
    # Método 2: Intentar activar por nombre de ventana usando AppleScript
    echo -e "${GREEN}🎯 Intentando activar ventana del emulador...${NC}"
    
    # Buscar ventanas que contengan "Android" o "Emulator"
    osascript -e '
      tell application "System Events"
        set windowList to {}
        repeat with proc in (every process whose background only is false)
          try
            set windowList to windowList & (every window of proc whose name contains "Android" or name contains "Emulator" or name contains "AVD")
          end try
        end repeat
        
        if (count of windowList) > 0 then
          set frontWindow to item 1 of windowList
          set frontmost of (process of frontWindow) to true
          return "Ventana del emulador encontrada y activada"
        else
          return "No se encontraron ventanas del emulador"
        end if
      end tell
    ' 2>/dev/null || true
    
    # Método 3: Intentar activar procesos específicos del emulador
    osascript -e 'tell application "System Events" to set frontmost of process "emulator" to true' 2>/dev/null || true
    osascript -e 'tell application "System Events" to set frontmost of process "qemu-system-x86_64" to true' 2>/dev/null || true
    osascript -e 'tell application "System Events" to set frontmost of process "qemu-system-aarch64" to true' 2>/dev/null || true
    
  else
    # En Windows o sistemas sin wmctrl, intentar con xdotool
    xdotool search --name "Android Emulator" windowactivate 2>/dev/null || xdotool search --name "emulator" windowactivate 2>/dev/null || true
  fi
  
  sleep 2
}

# Función para matar el proceso que usa el puerto 8080
kill_port_8080() {
  local pid=$(lsof -ti:8080)
  if [ ! -z "$pid" ]; then
    echo -e "${YELLOW}Matando proceso $pid que usa el puerto 8080...${NC}"
    kill -9 $pid 2>/dev/null
    sleep 1
  fi
}

# Lanzando iOS
if [ "$LAUNCH_IOS" = true ]; then
  create_box "🍎 Lanzando iOS" "$ORANGE"
  
  # Variable de control para el foco de iOS (solo una vez)
  IOS_FOCUS_APPLIED=false
  
  flutter run -d "$ios_device_id" | while read line; do
    echo -e "${ORANGE}[iOS]${NC} $line"
    
    # Detectar cuando la app está a punto de abrirse y dar foco al simulador (SOLO UNA VEZ)
    if [[ "$IOS_FOCUS_APPLIED" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing app"* ]]); then
      echo -e "\n${ORANGE}🎯 Aplicación instalándose, dando foco al simulador...${NC}"
      
      # Marcar que ya se aplicó el foco
      IOS_FOCUS_APPLIED=true
      
      focus_ios_simulator
    fi
    
    # Detectar cuando la app está lista
    if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
      echo -e "\n${ORANGE}✅ iOS listo: Simulador $ios_device_id${NC}\n"
    fi
    if [[ "$line" == *"Running with sound null safety"* ]]; then
      echo -e "\n${ORANGE}✅ iOS listo: Simulador $ios_device_id${NC}\n"
    fi
    if [[ "$line" == *"Syncing files to device"* ]]; then
      echo -e "\n${ORANGE}✅ iOS listo: Simulador $ios_device_id${NC}\n"
    fi
  done &
fi

# Lanzando Pixel 9
if [ "$LAUNCH_PIXEL_9" = true ]; then
  create_box "🟢 Lanzando Pixel 9" "$GREEN"
  
  # Variable de control para el foco de Pixel 9 (solo una vez)
  PIXEL9_FOCUS_APPLIED=false
  
  flutter run -d "$pixel9_device_id" | while read line; do
    echo -e "${GREEN}[Pixel 9]${NC} $line"
    
    # Detectar cuando la app está a punto de abrirse y dar foco al emulador (SOLO UNA VEZ)
    if [[ "$PIXEL9_FOCUS_APPLIED" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing APK"* ]]); then
      echo -e "\n${GREEN}🎯 Aplicación instalándose, dando foco al emulador...${NC}"
      
      # Marcar que ya se aplicó el foco
      PIXEL9_FOCUS_APPLIED=true
      
      focus_android_emulator
    fi
    
    # Detectar cuando la app está lista
    if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
      echo -e "\n${GREEN}✅ Pixel 9 listo: Emulador $pixel9_device_id${NC}\n"
    fi
    if [[ "$line" == *"Running with sound null safety"* ]]; then
      echo -e "\n${GREEN}✅ Pixel 9 listo: Emulador $pixel9_device_id${NC}\n"
    fi
    if [[ "$line" == *"Syncing files to device"* ]]; then
      echo -e "\n${GREEN}✅ Pixel 9 listo: Emulador $pixel9_device_id${NC}\n"
    fi
  done &
fi

# Lanzando Pixel 9 (2) (si tienes otro emulador)
if [ "$LAUNCH_PIXEL_9_2" = true ]; then
  create_box "🟢 Lanzando Pixel 9 (2)" "$GREEN"
  
  # Variable de control para el foco de Pixel 9 (2) (solo una vez)
  PIXEL9_2_FOCUS_APPLIED=false
  
  flutter run -d "$pixel9_2_device_id" | while read line; do
    echo -e "${GREEN}[Pixel 9 (2)]${NC} $line"
    
    # Detectar cuando la app está a punto de abrirse y dar foco al emulador (SOLO UNA VEZ)
    if [[ "$PIXEL9_2_FOCUS_APPLIED" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing APK"* ]]); then
      echo -e "\n${GREEN}🎯 Aplicación instalándose, dando foco al emulador...${NC}"
      
      # Marcar que ya se aplicó el foco
      PIXEL9_2_FOCUS_APPLIED=true
      
      focus_android_emulator
    fi
    
    # Detectar cuando la app está lista
    if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
      echo -e "\n${GREEN}✅ Pixel 9 (2) listo: Emulador $pixel9_2_device_id${NC}\n"
    fi
    if [[ "$line" == *"Running with sound null safety"* ]]; then
      echo -e "\n${GREEN}✅ Pixel 9 (2) listo: Emulador $pixel9_2_device_id${NC}\n"
    fi
    if [[ "$line" == *"Syncing files to device"* ]]; then
      echo -e "\n${GREEN}✅ Pixel 9 (2) listo: Emulador $pixel9_2_device_id${NC}\n"
    fi
  done &
fi

# Lanzando Web Server
if [ "$LAUNCH_WEB" = true ]; then
  create_box "🖥 Lanzando WEB" "$BLUE"
  kill_port_8080
  flutter run -d web-server --web-port=8080 | while read line; do
    echo -e "${BLUE}[Web]${NC} $line"
    if [[ "$line" == *"Serving DevTools at"* || "$line" == *"The Flutter DevTools debugger and profiler on the Web is available at:"* || "$line" == *"Running with sound null safety"* || "$line" == *"lib/main.dart is being served at"* || "$line" == *"Serving at http://localhost:8080"* || "$line" == *"To hot restart"* ]]; then
      echo -e "\n${BLUE}✅ Web lista: http://localhost:8080${NC}\n"
    fi
  done &
fi

wait 