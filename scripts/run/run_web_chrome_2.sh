#!/bin/bash

echo -ne "\033]0;run_web_mobile_2\007"

# Definición de colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
NC='\033[0m'

echo -e "${BLUE}📱 Lanzando aplicación web en modo móvil (2 dispositivos)${NC}"

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


# Matar procesos en los puertos que vamos a usar
kill_port 8080
kill_port 8081

echo -e "\n${BLUE}🚀 Iniciando primera instancia en puerto 8080 (iPhone)...${NC}"

# Primera instancia en puerto 8080 - iPhone
flutter run -d chrome --web-port=8080 --web-hostname=localhost | while read line; do
  echo -e "${BLUE}[iPhone:8080]${NC} $line"
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${GREEN}✅ Primera instancia lista: iPhone en puerto 8080${NC}\n"
    # Activar modo responsive automáticamente
    osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null || true
    sleep 2
    osascript -e 'tell application "System Events" to keystroke "m" using {command down, shift down}' 2>/dev/null || true
    # Cambiar título a iPhone
    sleep 1
    osascript -e 'tell application "Google Chrome"
      repeat with w in windows
        repeat with t in tabs of w
          if URL of t contains "localhost:8080" then
            tell t to execute javascript "document.title = \"iPhone - The Final Burger\""
            exit repeat
          end if
        end repeat
      end repeat
    end tell' 2>/dev/null || true
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${GREEN}✅ Primera instancia lista: iPhone en puerto 8080${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${GREEN}✅ Primera instancia lista: iPhone en puerto 8080${NC}\n"
  fi
done &

# Esperar un poco para que la primera instancia se inicie
sleep 3

echo -e "\n${BLUE}🚀 Iniciando segunda instancia en puerto 8081 (Android)...${NC}"

# Segunda instancia en puerto 8081 - Android
flutter run -d chrome --web-port=8081 --web-hostname=localhost | while read line; do
  echo -e "${GREEN}[Android:8081]${NC} $line"
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${GREEN}✅ Segunda instancia lista: Android en puerto 8081${NC}\n"
    # Activar modo responsive automáticamente
    osascript -e 'tell application "Google Chrome" to activate' 2>/dev/null || true
    sleep 2
    osascript -e 'tell application "System Events" to keystroke "m" using {command down, shift down}' 2>/dev/null || true
    # Cambiar título a Android
    sleep 1
    osascript -e 'tell application "Google Chrome"
      repeat with w in windows
        repeat with t in tabs of w
          if URL of t contains "localhost:8081" then
            tell t to execute javascript "document.title = \"Android - The Final Burger\""
            exit repeat
          end if
        end repeat
      end repeat
    end tell' 2>/dev/null || true
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${GREEN}✅ Segunda instancia lista: Android en puerto 8081${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${GREEN}✅ Segunda instancia lista: Android en puerto 8080${NC}\n"
  fi
done &

echo -e "\n${GREEN}🎉 Ambas instancias iniciadas en modo móvil:${NC}"
echo -e "${GREEN}   📱 iPhone: http://localhost:8080${NC}"
echo -e "${GREEN}   📱 Android: http://localhost:8081${NC}"
echo -e "\n${BLUE}💡 Instrucciones:${NC}"
echo -e "${BLUE}   1. Cada ventana se abrirá automáticamente en modo responsive${NC}"
echo -e "${BLUE}   2. Si no se activa automáticamente, presiona Cmd+Shift+M${NC}"
echo -e "${BLUE}   3. Selecciona diferentes dispositivos en cada ventana${NC}"
echo -e "${BLUE}   4. Las DevTools estarán minimizadas para ahorrar espacio${NC}"
echo -e "${BLUE}   5. Las ventanas se reposicionarán automáticamente${NC}"

# Esperar a que ambas aplicaciones estén completamente cargadas antes de reposicionar
echo -e "\n${BLUE}⏳ Esperando a que ambas aplicaciones estén completamente cargadas...${NC}"
sleep 25

# Función para reposicionar ventanas usando AppleScript directo
reposition_flutter_windows() {
  echo -e "${BLUE}🔄 Reposicionando ventanas de Flutter...${NC}"
  
  # Listar todas las ventanas para debug
  echo -e "${BLUE}🔍 Listando todas las ventanas de Chrome...${NC}"
  osascript -e 'tell application "Google Chrome"
    set windowList to {}
    repeat with w in windows
      set {x, y, width, height} to bounds of w
      set end of windowList to {(name of w) & " - x: " & x & ", y: " & y & ", w: " & width & ", h: " & height}
    end repeat
    return windowList
  end tell' 2>/dev/null || echo "Error listando ventanas"
  
  # Intentar reposicionar todas las ventanas que contengan "localhost" o "The Final Burger"
  echo -e "${BLUE}📱 Reposicionando ventanas con localhost o The Final Burger...${NC}"
  osascript -e 'tell application "Google Chrome"
    set windowCount to 0
    repeat with w in windows
      set windowName to name of w
      if windowName contains "localhost" or windowName contains "The Final Burger" or windowName contains "8080" or windowName contains "8081" then
        set windowCount to windowCount + 1
        if windowCount is 1 then
          set bounds of w to {0, 38, 500, 893}
          log "Ventana 1 reposicionada a {0, 38, 500, 893}"
        else if windowCount is 2 then
          set bounds of w to {414, 38, 946, 893}
          log "Ventana 2 reposicionada a {414, 38, 946, 893}"
        end if
      end if
    end repeat
    return windowCount
  end tell' 2>/dev/null || echo "Error reposicionando ventanas"
  
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

# Ejecutar reposicionamiento usando la función definida arriba con las nuevas coordenadas
echo -e "\n${BLUE}🔄 Ejecutando reposicionamiento de ventanas con coordenadas personalizadas...${NC}"
reposition_flutter_windows

# Cambiar títulos después del reposicionamiento para asegurar que funcione
echo -e "\n${BLUE}📝 Cambiando títulos de ventanas...${NC}"
osascript -e 'tell application "Google Chrome"
  repeat with w in windows
    repeat with t in tabs of w
      if URL of t contains "localhost:8080" then
        tell t to execute javascript "document.title = \"iPhone - The Final Burger\""
      else if URL of t contains "localhost:8081" then
        tell t to execute javascript "document.title = \"Android - The Final Burger\""
      end if
    end repeat
  end repeat
end tell' 2>/dev/null || true

# Script Python original comentado para mantener las coordenadas personalizadas de este script
# python3 ./scripts/run/reposition_flutter_windows.py

# Esperar a que ambos procesos terminen
wait

