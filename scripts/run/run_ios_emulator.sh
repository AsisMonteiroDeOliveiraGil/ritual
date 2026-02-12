#!/bin/bash

echo -ne "\033]0;run_ios_emulator\007"

# Definición de colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
ORANGE='\033[38;5;208m'
NC='\033[0m'

echo -e "${ORANGE}🍎 Lanzando simulador iOS...${NC}"

# Verificar si el simulador iOS está corriendo
SIMULATOR_PROCESS=$(ps aux | grep -i "Simulator.app" | grep -v grep | head -1)

if [ -z "$SIMULATOR_PROCESS" ]; then
  echo -e "${ORANGE}🚀 El simulador iOS no está corriendo, iniciándolo...${NC}"
  
  # Abrir el simulador iOS
  open -a Simulator
  
  # Esperar a que el simulador se inicie
  echo -e "${ORANGE}⏳ Esperando a que el simulador iOS se inicie...${NC}"
  MAX_WAIT=60
  WAIT_COUNT=0
  while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Verificar si el proceso Simulator está corriendo
    SIMULATOR_PROCESS=$(ps aux | grep -i "Simulator.app" | grep -v grep | head -1)
    if [ -n "$SIMULATOR_PROCESS" ]; then
      echo -e "${GREEN}✅ Simulador iOS iniciado${NC}"
      break
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $((WAIT_COUNT % 5)) -eq 0 ]; then
      echo -e "${ORANGE}⏳ Esperando... ($WAIT_COUNT/$MAX_WAIT)${NC}"
    fi
  done
  
  if [ -z "$SIMULATOR_PROCESS" ]; then
    echo -e "${YELLOW}⚠️  El simulador no se detectó en el tiempo esperado, pero continuando...${NC}"
  fi
else
  echo -e "${GREEN}✅ Simulador iOS ya está corriendo${NC}"
fi

# Esperar un poco más para asegurar que la ventana esté completamente cargada
echo -e "${ORANGE}⏳ Esperando a que la ventana del simulador esté completamente cargada...${NC}"
sleep 8

# Activar el simulador para asegurar que esté visible
osascript -e 'tell application "Simulator" to activate' 2>/dev/null || true
sleep 2

# Reposicionar ventana del simulador iOS
echo -e "${ORANGE}🔄 Reposicionando ventana del simulador iOS...${NC}"
osascript -e 'tell application "System Events"
  tell process "Simulator"
    repeat with w in windows
      try
        set position of w to {3, 38}
        set size of w to {400, 856}
        log "Simulador iOS reposicionado a posición {3, 38} y tamaño {400, 856}"
      end try
    end repeat
  end tell
end tell' 2>&1

# Reposicionar ventana de Cursor
echo -e "${ORANGE}💻 Reposicionando ventana de Cursor...${NC}"
osascript -e 'tell application "System Events"
  tell process "Cursor"
    tell window 1
      set position to {407, 38}
      set size to {1105, 854}
      log "Ventana Cursor reposicionada a posición {407, 38} y tamaño {1105, 854}"
    end tell
  end tell
end tell' 2>/dev/null || echo "⚠️  Error reposicionando ventana de Cursor"

echo -e "${GREEN}✅ Reposicionamiento completado${NC}"

