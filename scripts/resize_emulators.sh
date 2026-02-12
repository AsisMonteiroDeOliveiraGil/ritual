#!/bin/bash

# Script para detectar, enfocar y redimensionar emuladores Android
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=monitor_detection.sh
source "${SCRIPT_DIR}/monitor_detection.sh"

EXTERNAL_MONITORS=$(detect_external_monitors)

if [ "${EXTERNAL_MONITORS:-0}" -gt 0 ]; then
  CURRENT_MODE="monitor"
  ANDROID_WIDTH=591
  ANDROID_HEIGHT=1249
  ANDROID_X=109
  ANDROID_Y=93

  IOS_WIDTH=637
  IOS_HEIGHT=1326
  IOS_X=821
  IOS_Y=25

  CURSOR_X=1612
  CURSOR_Y=25
  CURSOR_WIDTH=2703
  CURSOR_HEIGHT=1325
else
  CURRENT_MODE="mac"
  ANDROID_WIDTH=348
  ANDROID_HEIGHT=748
  ANDROID_X=1
  ANDROID_Y=105

  IOS_WIDTH=348
  IOS_HEIGHT=748
  IOS_X=412
  IOS_Y=38

  CURSOR_X=788
  CURSOR_Y=38
  CURSOR_WIDTH=724
  CURSOR_HEIGHT=858
fi

if [ "$CURRENT_MODE" = "monitor" ]; then
  SIMULATOR_SCALE_SNIPPET=$'      -- Ajustar escala del Simulator al máximo (Cmd+4)\n      keystroke "4" using command down\n      delay 1\n'
else
  SIMULATOR_SCALE_SNIPPET=$'      -- Usar atajo de teclado para establecer el Simulator a escala menor (Cmd+1)\n      -- Esto establece el tamaño mínimo permitido por el simulador\n      keystroke "1" using command down\n      delay 1\n'
fi

echo "🔍 Detectando emuladores activos..."

# Obtener lista de emuladores conectados (Android)
connected_devices=$(adb devices | grep 'emulator-' | awk '{print $1}')

if [ -z "$connected_devices" ]; then
  echo "⚠️  No se detectaron emuladores Android por adb"
  echo "ℹ️  Continuaré buscando ventanas de iOS Simulator/Android abiertas"
else
  # Contar emuladores
  emulator_count=$(echo "$connected_devices" | wc -l | xargs)
  echo "✅ Encontrados $emulator_count emulador(es) Android activos"
fi

# Array para almacenar las ventanas del emulador
declare -a emulator_windows

# Buscar ventanas de emulador usando AppleScript
echo "🔍 Buscando ventanas de emulador y simulador..."

# Obtener todas las ventanas de emuladores Android y simuladores iOS
emulator_windows=$(osascript -e '
tell application "System Events"
  set windowList to ""
  set appList to every process whose background only is false
  repeat with proc in appList
    try
      set procName to name of proc
      if procName contains "Emulator" or procName contains "qemu" or procName contains "Simulator" then
        set windowCount to count of windows of proc
        if windowCount > 0 then
          repeat with win in windows of proc
            set winName to name of win
            set windowList to windowList & procName & "|" & winName & "\n"
          end repeat
        end if
      end if
    end try
  end repeat
  return windowList
end tell
' 2>/dev/null)

if [ -z "$emulator_windows" ]; then
  echo "⚠️  No se encontraron ventanas de emulador/simulador abiertas"
  echo "ℹ️  Los emuladores pueden estar minimizados o el nombre de la aplicación puede ser diferente"
  exit 1
fi

echo "📱 Ventanas encontradas:"
echo "$emulator_windows" | grep -v '^$'

# Redimensionar cada ventana de emulador/simulador
echo ""
echo "📐 Redimensionando y posicionando emuladores/simuladores..."

index=1

echo "📏 Android objetivo: ${ANDROID_WIDTH}x${ANDROID_HEIGHT}"
echo "📏 iOS objetivo: ${IOS_WIDTH}x${IOS_HEIGHT}"

# Procesar cada ventana encontrada
while IFS='|' read -r app_name window_name; do
  if [ -n "$app_name" ] && [ -n "$window_name" ]; then
    echo "  [$index] Procesando: $app_name - $window_name"
    
    # Determinar la posición según el tipo de emulador
    if [[ "$app_name" == "Simulator" ]]; then
      TARGET_X=$IOS_X
      TARGET_Y=$IOS_Y
    else
      TARGET_X=$ANDROID_X
      TARGET_Y=$ANDROID_Y
    fi
    
    # Usar AppleScript para redimensionar y posicionar la ventana
    if [[ "$app_name" == "Simulator" ]]; then
      echo "    📱 Redimensionando $app_name a tamaño: ${IOS_WIDTH}x${IOS_HEIGHT}"
    else
      echo "    📱 Redimensionando $app_name a tamaño: ${ANDROID_WIDTH}x${ANDROID_HEIGHT}"
    fi
    echo "    📍 Posicionando en: ($TARGET_X, $TARGET_Y)"
    
    if [[ "$app_name" == "Simulator" ]]; then
      # Para iOS Simulator, primero ajustar el scale y luego posicionar
      echo "    🍎 Detectado iOS Simulator - Ajustando escala y posición..."
      osascript <<EOF 2>/dev/null
tell application "Simulator"
  activate
  delay 1
end tell

tell application "System Events"
  tell process "Simulator"
    try
      set frontmost to true
      delay 1
      
${SIMULATOR_SCALE_SNIPPET}
      
      -- Ahora trabajar con la ventana específica
      tell window "$window_name"
        -- Posicionar la ventana en la ubicación exacta
        set position to {$TARGET_X, $TARGET_Y}
        delay 0.5
        try
          set size to {${IOS_WIDTH}, ${IOS_HEIGHT}}
          delay 0.5
        end try
        
        -- Reportar tamaño final
        set finalSize to size
        return "iOS Final: " & item 1 of finalSize & "x" & item 2 of finalSize
      end tell
    end try
  end tell
end tell
EOF
    else
      # Para Android Emulator
      echo "    🤖 Detectado Android Emulator - Aplicando resize..."
      osascript <<EOF 2>/dev/null
tell application "System Events"
  tell process "$app_name"
    try
      set frontmost to true
      delay 2
      tell window "$window_name"
        -- Posicionar en la ubicación exacta
        set position to {$TARGET_X, $TARGET_Y}
        delay 0.5
        
        -- Aplicar tamaño
        set size to {${ANDROID_WIDTH}, ${ANDROID_HEIGHT}}
        delay 0.5
        
        -- Verificar y reportar tamaño final
        set currentSize to size of window "$window_name"
        set currentPos to position of window "$window_name"
        return "Android Final: " & item 1 of currentSize & "x" & item 2 of currentSize
      end tell
    end try
  end tell
end tell
EOF
    fi
    
    # Mostrar resultado
    if [[ "$app_name" == "Simulator" ]]; then
      echo "  ✅ $app_name procesado - Tamaño objetivo: ${IOS_WIDTH}x${IOS_HEIGHT} en posición ($TARGET_X, $TARGET_Y)"
    else
      echo "  ✅ $app_name procesado - Tamaño objetivo: ${ANDROID_WIDTH}x${ANDROID_HEIGHT} en posición ($TARGET_X, $TARGET_Y)"
    fi
    
    index=$((index + 1))
  fi
done <<< "$emulator_windows"

# Reposicionar Cursor
echo ""
echo "💻 Reposicionando ventana de Cursor..."
osascript <<EOF 2>/dev/null
tell application "System Events"
  tell process "Cursor"
    try
      set frontmost to true
      delay 0.5
      
      -- Trabajar con la primera ventana (ventana principal)
      if (count of windows) > 0 then
        tell window 1
          set position to {$CURSOR_X, $CURSOR_Y}
          delay 0.3
          set size to {$CURSOR_WIDTH, $CURSOR_HEIGHT}
          delay 0.3
          
          -- Obtener nombre de la ventana para confirmar
          set winName to name
          return "Cursor reposicionado: " & winName & " - ${CURSOR_WIDTH}x${CURSOR_HEIGHT} en ($CURSOR_X, $CURSOR_Y)"
        end tell
      end if
    end try
  end tell
end tell
EOF
echo "  ✅ Cursor reposicionado"

echo ""
echo "✨ Proceso completado"
echo ""
echo "ℹ️  Configuración actual:"
echo "    Android Emulator: ${ANDROID_WIDTH}x${ANDROID_HEIGHT} en posición ($ANDROID_X, $ANDROID_Y)"
echo "    iOS Simulator: ${IOS_WIDTH}x${IOS_HEIGHT} en posición ($IOS_X, $IOS_Y)"
echo "    Cursor: ${CURSOR_WIDTH}x${CURSOR_HEIGHT} en posición ($CURSOR_X, $CURSOR_Y)"

if [ "${EXTERNAL_MONITORS:-0}" -gt 0 ]; then
  echo "MODO MONITOR"
else
  echo "MODO MAC"
fi
