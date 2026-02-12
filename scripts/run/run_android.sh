#!/bin/bash

# Definición de colores
GREEN='\033[38;5;46m'  # Un verde más intenso y vibrante
YELLOW='\033[38;5;226m'  # Amarillo para advertencias
RED='\033[38;5;196m'  # Rojo para errores
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Iniciando lanzamiento de Android...${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ Error: No se encontró pubspec.yaml. Asegúrate de estar en el directorio raíz del proyecto.${NC}"
  exit 1
fi

# Exportar la API Key de Google Maps desde el .env
if [ -f .env ]; then
  export ANDROID_API_KEY=$(grep ANDROID_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  
  # Verificar que la API key no esté vacía
  if [ -n "$ANDROID_API_KEY" ] && [ "$ANDROID_API_KEY" != "YOUR_API_KEY" ]; then
    echo -e "${GREEN}✅ ANDROID_API_KEY exportada: ${ANDROID_API_KEY:0:10}...${NC}"
  else
    echo -e "${YELLOW}⚠️  ANDROID_API_KEY está vacía o no configurada correctamente${NC}"
  fi
else
  echo -e "${RED}❌ Archivo .env no encontrado. No se exportó ANDROID_API_KEY.${NC}"
  exit 1
fi

# Verificar que Flutter esté disponible
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Error: Flutter no está instalado o no está en el PATH${NC}"
  exit 1
fi

# Mostrar información del emulador seleccionado
echo -e "\n${GREEN}📱 Emulador seleccionado: Pixel 9${NC}"
echo -e "${GREEN}🆔 ID: emulator-5554${NC}"

# Variable de control para el foco (solo una vez)
FOCUS_APPLIED=false

# Lanzando Android
echo -e "\n${GREEN}🤖 Lanzando en Android (Emulador emulator-5554)${NC}"
echo -e "${GREEN}🔧 Usando API Key: ${ANDROID_API_KEY:0:10}...${NC}\n"

flutter run -d "emulator-5554" | while read line; do
  # Solo mostrar líneas importantes, no todo el output
  if [[ "$line" == *"🎯"* ]] || [[ "$line" == *"✅"* ]] || [[ "$line" == *"Error"* ]] || [[ "$line" == *"Exception"* ]] || [[ "$line" == *"Failed"* ]]; then
    echo -e "${GREEN}[Android]${NC} $line"
  fi
  
  # Detectar cuando la app está a punto de abrirse y dar foco al emulador (SOLO UNA VEZ)
  if [[ "$FOCUS_APPLIED" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing APK"* ]]); then
    echo -e "\n${GREEN}🎯 Aplicación instalándose, dando foco al emulador...${NC}"
    
    # Marcar que ya se aplicó el foco
    FOCUS_APPLIED=true
    
    # Dar foco al emulador de Android para que aparezca por encima de todas las aplicaciones
    if command -v wmctrl &> /dev/null; then
      # En sistemas Linux con wmctrl
      wmctrl -a "Android Emulator" 2>/dev/null || wmctrl -a "emulator" 2>/dev/null || true
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      # En macOS, usar métodos más efectivos para dar foco al emulador
      
      # Método 2: Intentar activar por nombre de ventana usando AppleScript
      echo -e "${GREEN}🎯 Activando ventana del emulador...${NC}"
      
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
    
    sleep 1
  fi
  
  # Detectar cuando la app está lista
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${GREEN}✅ Android listo: Emulador emulator-5554${NC}\n"
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${GREEN}✅ Android listo: Emulador emulator-5554${NC}\n"
  fi
done 