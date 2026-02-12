#!/bin/bash

echo "🎯 Capturando posiciones EXACTAS de las ventanas..."
echo ""
echo "IMPORTANTE: Asegúrate de que las ventanas están EXACTAMENTE donde las quieres"
echo ""

# Encontrar los PIDs actuales
PID_8080=$(ps aux | grep "localhost:8080" | grep "Google Chrome" | grep -v grep | awk '{print $2}' | head -1)
PID_8081=$(ps aux | grep "localhost:8081" | grep "Google Chrome" | grep -v grep | awk '{print $2}' | head -1)

echo "PIDs encontrados:"
echo "  - 8080: $PID_8080"
echo "  - 8081: $PID_8081"
echo ""

if [ -z "$PID_8080" ] || [ -z "$PID_8081" ]; then
  echo "❌ No se encontraron los procesos de Flutter"
  exit 1
fi

echo "=== POSICIONES ACTUALES ==="
# Capturar ventana 8080
echo "📱 Capturando Ventana 8080 (iPhone)..."
osascript -e "
tell application \"System Events\"
  try
    tell (first process whose unix id is $PID_8080)
      tell window 1
        set winPos to position
        set winSize to size
        set xPos to item 1 of winPos
        set yPos to item 2 of winPos
        set winWidth to item 1 of winSize
        set winHeight to item 2 of winSize
        log \"📱 Ventana 8080 (iPhone):\"
        log \"   Posición: {\" & xPos & \", \" & yPos & \"}\"
        log \"   Tamaño: {\" & winWidth & \", \" & winHeight & \"}\"
        log \"   Bounds: {\" & xPos & \", \" & yPos & \", \" & (xPos + winWidth) & \", \" & (yPos + winHeight) & \"}\"
      end tell
    end tell
  on error errMsg
    log \"⚠️  Error: \" & errMsg
  end try
end tell
" 2>&1

# Capturar ventana 8081
echo ""
echo "📱 Capturando Ventana 8081 (Android)..."
osascript -e "
tell application \"System Events\"
  try
    tell (first process whose unix id is $PID_8081)
      tell window 1
        set winPos to position
        set winSize to size
        set xPos to item 1 of winPos
        set yPos to item 2 of winPos
        set winWidth to item 1 of winSize
        set winHeight to item 2 of winSize
        log \"📱 Ventana 8081 (Android):\"
        log \"   Posición: {\" & xPos & \", \" & yPos & \"}\"
        log \"   Tamaño: {\" & winWidth & \", \" & winHeight & \"}\"
        log \"   Bounds: {\" & xPos & \", \" & yPos & \", \" & (xPos + winWidth) & \", \" & (yPos + winHeight) & \"}\"
      end tell
    end tell
  on error errMsg
    log \"⚠️  Error: \" & errMsg
  end try
end tell
" 2>&1

# Capturar ventana Cursor
echo ""
echo "💻 Capturando Ventana Cursor..."
osascript -e '
tell application "System Events"
  try
    tell process "Cursor"
      tell window 1
        set winPos to position
        set winSize to size
        set xPos to item 1 of winPos
        set yPos to item 2 of winPos
        set winWidth to item 1 of winSize
        set winHeight to item 2 of winSize
        log "💻 Ventana Cursor:"
        log "   Posición: {" & xPos & ", " & yPos & "}"
        log "   Tamaño: {" & winWidth & ", " & winHeight & "}"
        log "   Bounds: {" & xPos & ", " & yPos & ", " & (xPos + winWidth) & ", " & (yPos + winHeight) & "}"
      end tell
    end tell
  on error errMsg
    log "⚠️  Error: " & errMsg
  end try
end tell
' 2>&1

# Capturar posición del cursor del mouse
echo ""
echo "🖱️  Capturando Posición del Cursor del Mouse..."
osascript -e '
tell application "System Events"
  set mousePos to mouse location
  set mouseX to item 1 of mousePos
  set mouseY to item 2 of mousePos
  log "🖱️  Posición del cursor:"
  log "   Coordenadas: {" & mouseX & ", " & mouseY & "}"
end tell
' 2>&1 | grep -E "(🖱️|Coordenadas)" || echo "⚠️  No se pudo capturar la posición del cursor del mouse"

echo ""
echo "✅ Captura completada. Estas son las coordenadas exactas actuales."

