#!/bin/bash

echo -ne "\033]0;reposition_windows\007"

# Definición de colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
NC='\033[0m'

echo -e "${BLUE}🔄 Reposicionando ventanas de Chrome...${NC}"

# Listar todas las ventanas disponibles
echo -e "${BLUE}🔍 Listando ventanas disponibles...${NC}"
osascript -e 'tell application "Google Chrome"
  repeat with w in windows
    set {x, y, width, height} to bounds of w
    log (name of w) & " - x: " & x & ", y: " & y & ", w: " & width & ", h: " & height
  end repeat
end tell'

# Reposicionar ventana 1 (8080) - lado izquierdo
echo -e "${BLUE}📱 Reposicionando ventana 1 (8080)...${NC}"
osascript -e 'tell application "Google Chrome"
  set windowCount to count of windows
  if windowCount >= 1 then
    set bounds of window 1 to {331, 38, 831, 896}
    log "Ventana 1 reposicionada a {331, 38, 831, 896}"
  else
    log "No hay ventanas disponibles"
  end if
end tell'

# Reposicionar ventana 2 (8081) - lado derecho
echo -e "${BLUE}📱 Reposicionando ventana 2 (8081)...${NC}"
osascript -e 'tell application "Google Chrome"
  set windowCount to count of windows
  if windowCount >= 2 then
    set bounds of window 2 to {100, 100, 740, 740}
    log "Ventana 2 reposicionada a {100, 100, 740, 740}"
  else
    log "Solo hay " & windowCount & " ventanas disponibles"
  end if
end tell'

echo -e "${GREEN}✅ Reposicionamiento completado${NC}"

# Verificar posiciones finales
echo -e "${BLUE}🔍 Verificando posiciones finales...${NC}"
osascript -e 'tell application "Google Chrome"
  repeat with w in windows
    set {x, y, width, height} to bounds of w
    log "Ventana: " & (name of w) & " - x: " & x & ", y: " & y & ", w: " & width & ", h: " & height
  end repeat
end tell'
