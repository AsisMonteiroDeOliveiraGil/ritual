#!/bin/bash

echo -ne "\033]0;run_web_mobile_1\007"

# Definición de colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
NC='\033[0m'

echo -e "${BLUE}📱 Lanzando aplicación web en modo móvil (Android)${NC}"

# Exportar la API Key de Google Maps desde el .env
if [ -f .env ]; then
  export WEB_API_KEY=$(grep WEB_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  echo -e "${BLUE}🔑 WEB_API_KEY exportada: ${WEB_API_KEY:0:10}...${NC}"
else
  echo -e "${BLUE}⚠️  Archivo .env no encontrado en la raíz. No se exportó WEB_API_KEY.${NC}"
fi

# Función para matar procesos en puerto
kill_port() {
  local port=$1
  echo -e "${YELLOW}🔍 Verificando puerto $port...${NC}"
  local pid=$(lsof -ti:$port 2>/dev/null)
  if [ ! -z "$pid" ]; then
    echo -e "${YELLOW}⚠️  Matando proceso en puerto $port (PID: $pid)${NC}"
    kill -9 $pid 2>/dev/null
    sleep 1
  else
    echo -e "${GREEN}✅ Puerto $port está libre${NC}"
  fi
}

# Matar procesos en el puerto que vamos a usar
kill_port 8080

echo -e "\n${BLUE}🚀 Iniciando instancia en puerto 8080 (Android)...${NC}"

# Instancia en puerto 8080 - Android
flutter run -d chrome --web-port=8080 --web-hostname=localhost | while read line; do
  echo -e "${GREEN}[Android:8080]${NC} $line"
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${GREEN}✅ Instancia lista: Android en puerto 8080${NC}\n"
    # Activar modo responsive automáticamente
    osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null || true
    sleep 2
    osascript -e 'tell application "System Events" to keystroke "m" using {command down, shift down}' 2>/dev/null || true
    # Cambiar título a Android
    sleep 1
    osascript -e 'tell application "Google Chrome"
      repeat with w in windows
        repeat with t in tabs of w
          if URL of t contains "localhost:8080" then
            tell t to execute javascript "document.title = \"Android - The Final Burger\""
            exit repeat
          end if
        end repeat
      end repeat
    end tell' 2>/dev/null || true
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${GREEN}✅ Instancia lista: Android en puerto 8080${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${GREEN}✅ Instancia lista: Android en puerto 8080${NC}\n"
  fi
done &

echo -e "\n${GREEN}🎉 Instancia iniciada en modo móvil:${NC}"
echo -e "${GREEN}   📱 Android: http://localhost:8080${NC}"
echo -e "\n${BLUE}💡 Instrucciones:${NC}"
echo -e "${BLUE}   1. La ventana se abrirá automáticamente en modo responsive${NC}"
echo -e "${BLUE}   2. Si no se activa automáticamente, presiona Cmd+Shift+M${NC}"
echo -e "${BLUE}   3. Selecciona el dispositivo Android${NC}"
echo -e "${BLUE}   4. Las ventanas se reposicionarán automáticamente${NC}"

# Esperar a que la aplicación esté completamente cargada antes de reposicionar
echo -e "\n${BLUE}⏳ Esperando a que la aplicación esté completamente cargada...${NC}"
sleep 25

# Función para reposicionar ventanas usando AppleScript directo
reposition_flutter_windows() {
  echo -e "${BLUE}🔄 Reposicionando ventanas de Flutter...${NC}"
  
  # Reposicionar ventana de Chrome con localhost:8080
  echo -e "${BLUE}📱 Reposicionando ventana de Chrome (8080)...${NC}"
  osascript -e 'tell application "Google Chrome"
    repeat with w in windows
      set windowName to name of w
      if windowName contains "localhost" or windowName contains "The Final Burger" or windowName contains "8080" then
        set bounds of w to {0, 38, 500, 893}
        log "Ventana Chrome reposicionada a {0, 38, 500, 893}"
      end if
    end repeat
  end tell' 2>/dev/null || echo "Error reposicionando ventana de Chrome"
  
  # Reposicionar ventana de Cursor
  echo -e "${BLUE}💻 Reposicionando ventana de Cursor...${NC}"
  osascript -e 'tell application "System Events"
    tell process "Cursor"
      tell window 1
        set position to {501, 38}
        set size to {1011, 854}
        log "Ventana Cursor reposicionada a posición {501, 38} y tamaño {1011, 854}"
      end tell
    end tell
  end tell' 2>/dev/null || echo "Error reposicionando ventana de Cursor"
  
  echo -e "${GREEN}✅ Reposicionamiento completado${NC}"
  
  # Verificar posiciones finales
  echo -e "${BLUE}🔍 Verificando posiciones finales...${NC}"
  osascript -e 'tell application "Google Chrome"
    repeat with w in windows
      set {x, y, width, height} to bounds of w
      log "Ventana: " & (name of w) & " - x: " & x & ", y: " & y & ", w: " & width & ", h: " & height
    end repeat
  end tell' 2>/dev/null || true
}

# Ejecutar reposicionamiento
echo -e "\n${BLUE}🔄 Ejecutando reposicionamiento de ventanas...${NC}"
reposition_flutter_windows

# Cambiar título después del reposicionamiento para asegurar que funcione
echo -e "\n${BLUE}📝 Cambiando título de ventana...${NC}"
osascript -e 'tell application "Google Chrome"
  repeat with w in windows
    repeat with t in tabs of w
      if URL of t contains "localhost:8080" then
        tell t to execute javascript "document.title = \"Android - The Final Burger\""
      end if
    end repeat
  end repeat
end tell' 2>/dev/null || true

# Esperar a que el proceso termine
wait

