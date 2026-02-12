#!/bin/bash

echo -ne "\033]0;run_android_emulator\007"

# Definición de colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
NC='\033[0m'

echo -e "${BLUE}🤖 Lanzando emulador Android...${NC}"

# Verificar si el proceso del emulador está corriendo
EMULATOR_PROCESS=$(ps aux | grep "qemu-system-aarch64" | grep -v grep | head -1)

if [ -z "$EMULATOR_PROCESS" ]; then
  echo -e "${BLUE}🚀 El emulador no está corriendo, iniciándolo...${NC}"
  
  # Ruta del emulador
  EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"
  
  if [ ! -f "$EMULATOR_PATH" ]; then
    echo -e "${YELLOW}⚠️  No se encontró el emulador en $EMULATOR_PATH${NC}"
    echo -e "${BLUE}💡 Intentando con otras rutas comunes...${NC}"
    
    # Intentar otras rutas posibles
    if [ -n "$ANDROID_HOME" ] && [ -f "$ANDROID_HOME/emulator/emulator" ]; then
      EMULATOR_PATH="$ANDROID_HOME/emulator/emulator"
    elif [ -n "$ANDROID_SDK_ROOT" ] && [ -f "$ANDROID_SDK_ROOT/emulator/emulator" ]; then
      EMULATOR_PATH="$ANDROID_SDK_ROOT/emulator/emulator"
    else
      echo -e "${YELLOW}⚠️  No se pudo encontrar el emulador. Por favor, inicia el emulador manualmente.${NC}"
      exit 1
    fi
  fi
  
  echo -e "${BLUE}🚀 Lanzando emulador Pixel_9...${NC}"
  # Lanzar el emulador sin guardar snapshot para evitar el diálogo
  # Usar -no-snapshot-save para que no pregunte sobre guardar el estado
  (
    cd /tmp
    nohup $EMULATOR_PATH -avd Pixel_9 -no-snapshot-load -no-snapshot-save > /dev/null 2>&1 &
    sleep 1
    exit 0
  ) &
  
  # Esperar un momento para que el proceso se inicie
  sleep 2
  
  # Desvincular completamente todos los procesos del shell actual
  disown -a 2>/dev/null || true
  
  # Script para cerrar automáticamente el diálogo de guardar snapshot si aparece
  (
    sleep 10
    for i in {1..15}; do
      osascript -e 'tell application "System Events"
        repeat with proc in processes
          set procName to name of proc
          if procName contains "qemu-system-aarch64" then
            tell proc
              set frontmost to true
              repeat with w in windows
                try
                  set winTitle to name of w
                  if winTitle contains "save" or winTitle contains "Save" or winTitle contains "quick boot" or winTitle contains "state" then
                    keystroke "n" -- Presionar "No" para cerrar el diálogo
                    return
                  end if
                end try
              end repeat
            end tell
          end if
        end repeat
      end tell' 2>/dev/null || true
      sleep 2
    done
  ) &
  
  # Esperar a que el emulador se inicie
  echo -e "${BLUE}⏳ Esperando a que el emulador se inicie...${NC}"
  MAX_WAIT=90
  WAIT_COUNT=0
  while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    EMULATOR_PROCESS=$(ps aux | grep "qemu-system-aarch64" | grep -v grep | head -1)
    if [ -n "$EMULATOR_PROCESS" ]; then
      echo -e "${GREEN}✅ Emulador iniciado${NC}"
      break
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $((WAIT_COUNT % 10)) -eq 0 ]; then
      echo -e "${BLUE}⏳ Esperando... ($WAIT_COUNT/$MAX_WAIT)${NC}"
    fi
  done
  
  if [ -z "$EMULATOR_PROCESS" ]; then
    echo -e "${YELLOW}⚠️  El emulador no se inició en el tiempo esperado, pero continuando...${NC}"
  fi
else
  echo -e "${GREEN}✅ Emulador Android ya está corriendo${NC}"
fi

# Esperar un poco más para asegurar que la ventana esté completamente cargada
echo -e "${BLUE}⏳ Esperando a que la ventana del emulador esté completamente cargada...${NC}"
sleep 5

# Reposicionar ventana del emulador Android
echo -e "${BLUE}🔄 Reposicionando ventana del emulador Android...${NC}"
osascript -e 'tell application "System Events"
  repeat with proc in processes
    set procName to name of proc
    if procName contains "qemu-system-aarch64" or procName contains "Android Emulator" then
      tell proc
        repeat with w in windows
          try
            set winTitle to name of w
            if winTitle contains "Android Emulator" or winTitle contains "Pixel" or winTitle contains "emulator" then
              set position of w to {2, 72}
              set size of w to {372, 786}
              log procName & " - Emulador Android reposicionado a posición {2, 72} y tamaño {372, 786}"
              return
            end if
          end try
        end repeat
      end tell
    end if
  end repeat
end tell' 2>&1 | grep -v "execution error" || echo "⚠️  Error reposicionando emulador Android"

# Reposicionar ventana de Cursor
echo -e "${BLUE}💻 Reposicionando ventana de Cursor...${NC}"
osascript -e 'tell application "System Events"
  tell process "Cursor"
    tell window 1
      set position to {444, 38}
      set size to {1068, 854}
      log "Ventana Cursor reposicionada a posición {444, 38} y tamaño {1068, 854}"
    end tell
  end tell
end tell' 2>/dev/null || echo "⚠️  Error reposicionando ventana de Cursor"

echo -e "${GREEN}✅ Reposicionamiento completado${NC}"

# Salir del script de manera que no afecte procesos en segundo plano
# Usar exec para reemplazar el shell actual con un proceso nulo que termine inmediatamente
exec true
