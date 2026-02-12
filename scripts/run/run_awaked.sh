#!/bin/bash

# Script para ejecutar Flutter en todos los dispositivos activos detectados automáticamente
# Uso: ./scripts/run/run_awaked.sh

# Definición de colores (mismos que los scripts existentes)
GREEN='\033[38;5;46m'      # Verde intenso para Android
ORANGE='\033[38;5;208m'    # Naranja intenso para iOS
BLUE='\033[38;5;39m'       # Azul brillante para Web
YELLOW='\033[1;33m'        # Amarillo para advertencias
RED='\033[38;5;196m'       # Rojo para errores
NC='\033[0m'               # No Color

# Asegurar que se ejecuta desde la raíz del proyecto
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR" || exit 1

# Target de Flutter para Ritual
FLUTTER_TARGET="lib/main.dart"

echo -e "${YELLOW}🚀 Iniciando lanzamiento automático en todos los dispositivos activos...${NC}"
echo -e "${BLUE}💡 iOS se lanzará simultáneamente con delays escalonados para evitar conflictos${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
  echo -e "${RED}❌ Error: No se encontró pubspec.yaml. Asegúrate de estar en el directorio raíz del proyecto.${NC}"
  exit 1
fi

# Verificar que el target de Flutter exista
if [ ! -f "$FLUTTER_TARGET" ]; then
  echo -e "${RED}❌ Error: No se encontró el target de Flutter: $FLUTTER_TARGET${NC}"
  exit 1
fi

# Exportar las API Keys de Google Maps desde el .env
if [ -f .env ]; then
  export ANDROID_API_KEY=$(grep ANDROID_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  export IOS_API_KEY=$(grep IOS_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  export WEB_API_KEY=$(grep WEB_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  echo -e "${GREEN}✅ API Keys exportadas correctamente${NC}"
else
  echo -e "${YELLOW}⚠️  Archivo .env no encontrado. Algunas funcionalidades pueden no funcionar.${NC}"
fi

# Verificar que Flutter esté disponible
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Error: Flutter no está instalado o no está en el PATH${NC}"
  exit 1
fi

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

# Función para detectar simuladores iOS activos
detect_ios_simulators() {
  echo -e "\n${ORANGE}🍎 Detectando simuladores iOS activos...${NC}"
  
  local ios_devices=()
  local booted_devices=$(xcrun simctl list devices | grep 'Booted' | grep -E 'iPhone|iPad' | head -5)
  
  if [ -z "$booted_devices" ]; then
    echo -e "${YELLOW}⚠️  No hay simuladores iOS activos${NC}"
    IOS_DEVICES=()
    return
  fi
  
  while IFS= read -r line; do
    if [[ "$line" =~ ([A-F0-9\-]{36}) ]]; then
      local device_id="${BASH_REMATCH[1]}"
      local device_name=$(echo "$line" | sed 's/ (.*//' | xargs)
      ios_devices+=("$device_id:$device_name")
      echo -e "${ORANGE}✅ Simulador iOS detectado: $device_name ($device_id)${NC}"
    fi
  done <<< "$booted_devices"
  
  # Asignar al array global
  IOS_DEVICES=("${ios_devices[@]}")
}

# Función para detectar emuladores Android activos
detect_android_emulators() {
  echo -e "\n${GREEN}🤖 Detectando emuladores Android activos...${NC}"
  
  local android_devices=()
  
  # Verificar que ADB esté disponible
  if ! command -v adb &> /dev/null; then
    if [ -d "$HOME/Library/Android/sdk/platform-tools" ]; then
      export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
      echo -e "${BLUE}🔧 ADB agregado al PATH desde Android SDK${NC}"
    else
      echo -e "${YELLOW}⚠️  ADB no disponible. No se pueden detectar emuladores Android.${NC}"
      ANDROID_DEVICES=()
      return
    fi
  fi
  
  # Iniciar servidor ADB
  adb start-server >/dev/null 2>&1
  
  # Debug: verificar que ADB funciona correctamente
  echo -e "${BLUE}🔍 Debug: Verificando dispositivos ADB...${NC}"
  local adb_output=$(adb devices 2>/dev/null)
  echo -e "${BLUE}🔍 ADB devices output:${NC}"
  echo "$adb_output"
  
  # Obtener dispositivos conectados - usar timeout para evitar bloqueos
  local connected_devices
  if command -v timeout &> /dev/null; then
    connected_devices=$(timeout 10 adb devices 2>/dev/null | grep 'emulator-' | head -5)
  else
    connected_devices=$(adb devices 2>/dev/null | grep 'emulator-' | head -5)
  fi
  
  if [ -z "$connected_devices" ]; then
    echo -e "${YELLOW}⚠️  No hay emuladores Android activos${NC}"
    ANDROID_DEVICES=()
    return
  fi
  
  # Debug: mostrar líneas detectadas
  echo -e "${BLUE}🔍 Líneas de emuladores detectadas:${NC}"
  echo "$connected_devices"
  
  # Procesar cada línea de dispositivo usando un array
  echo -e "${BLUE}🔍 Iniciando procesamiento de líneas...${NC}"
  
  # Convertir el string en array de líneas
  local device_lines=()
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    device_lines+=("$line")
  done <<< "$connected_devices"
  
  for line in "${device_lines[@]}"; do
    echo -e "${BLUE}🔍 Procesando línea: '$line'${NC}"
    if [[ "$line" =~ (emulator-[0-9]+) ]]; then
      local device_id="${BASH_REMATCH[1]}"
      echo -e "${BLUE}🔍 Device ID extraído: $device_id${NC}"
      
      # Obtener información detallada del dispositivo
      local device_info=$(adb -s "$device_id" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
      local device_brand=$(adb -s "$device_id" shell getprop ro.product.brand 2>/dev/null || echo "Android")
      local device_version=$(adb -s "$device_id" shell getprop ro.build.version.release 2>/dev/null || echo "")
      
      # Crear nombre descriptivo del dispositivo
      local device_name="Android Emulator"
      if [ "$device_info" != "Unknown" ] && [ "$device_info" != "" ]; then
        if [ ! -z "$device_version" ]; then
          device_name="$device_brand $device_info (Android $device_version)"
        else
          device_name="$device_brand $device_info"
        fi
      else
        # Fallback: usar información del AVD si está disponible
        local avd_name=$(adb -s "$device_id" shell getprop ro.kernel.qemu 2>/dev/null)
        if [ "$avd_name" = "1" ]; then
          device_name="Android Emulator ($device_id)"
        fi
      fi
      
      android_devices+=("$device_id:$device_name")
      echo -e "${GREEN}✅ Emulador Android detectado: $device_name ($device_id)${NC}"
    else
      echo -e "${YELLOW}⚠️  Línea no coincide con patrón de emulador: '$line'${NC}"
    fi
  done
  
  if [ ${#android_devices[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No se detectaron emuladores Android vía ADB. Intentando con 'flutter devices'...${NC}"
    
    if command -v flutter &> /dev/null && command -v python3 &> /dev/null; then
      local flutter_json
      flutter_json=$(flutter devices --machine 2>/dev/null | python3 - <<'PY'
import json, sys
try:
    devices = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for device in devices:
    if device.get("platformType") == "android" and device.get("emulator"):
        identifier = device.get("id", "")
        name = device.get("name", "Android Emulator")
        if not identifier:
            continue
        sanitized = name.replace("\n", " ").replace(":", "-").strip()
        print(f"{identifier}:{sanitized}")
PY
)
      if [ -n "$flutter_json" ]; then
        while IFS= read -r device_line; do
          [ -z "$device_line" ] && continue
          android_devices+=("$device_line")
          device_id="${device_line%%:*}"
          device_name="${device_line#*:}"
          echo -e "${GREEN}✅ Emulador Android detectado (flutter): $device_name ($device_id)${NC}"
        done <<< "$flutter_json"
      else
        echo -e "${YELLOW}⚠️  'flutter devices' no devolvió emuladores Android.${NC}"
      fi
    else
      echo -e "${YELLOW}⚠️  No se pudo usar 'flutter devices' para detectar emuladores (falta flutter o python3).${NC}"
    fi
  fi
  
  # Debug: mostrar array final
  echo -e "${BLUE}🔍 Array final de dispositivos Android:${NC}"
  for device in "${android_devices[@]}"; do
    echo -e "${BLUE}  - $device${NC}"
  done
  
  # Asignar al array global
  ANDROID_DEVICES=("${android_devices[@]}")
}

# Función para detectar dispositivos Android físicos inalámbricos
detect_physical_android() {
  echo -e "\n${GREEN}📱 Detectando dispositivos Android físicos inalámbricos...${NC}"
  
  local physical_devices=()
  
  if ! command -v adb &> /dev/null; then
    PHYSICAL_ANDROID_DEVICES=()
    return
  fi
  
  # Buscar dispositivos inalámbricos
  local wireless_devices=$(adb devices | grep ':5555' | head -3)
  
  if [ -z "$wireless_devices" ]; then
    echo -e "${YELLOW}⚠️  No hay dispositivos Android físicos inalámbricos${NC}"
    PHYSICAL_ANDROID_DEVICES=()
    return
  fi
  
  while IFS= read -r line; do
    if [[ "$line" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):5555 ]]; then
      local device_ip="${BASH_REMATCH[1]}"
      local device_id="$device_ip:5555"
      
      # Obtener información detallada del dispositivo físico
      local device_info=$(adb -s "$device_id" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
      local device_brand=$(adb -s "$device_id" shell getprop ro.product.brand 2>/dev/null || echo "Android")
      local device_version=$(adb -s "$device_id" shell getprop ro.build.version.release 2>/dev/null || echo "")
      
      # Crear nombre descriptivo del dispositivo
      local device_name="Android Físico ($device_ip)"
      if [ "$device_info" != "Unknown" ] && [ "$device_info" != "" ]; then
        if [ ! -z "$device_version" ]; then
          device_name="$device_brand $device_info (Android $device_version) - $device_ip"
        else
          device_name="$device_brand $device_info - $device_ip"
        fi
      fi
      
      physical_devices+=("$device_id:$device_name")
      echo -e "${GREEN}✅ Dispositivo físico detectado: $device_name${NC}"
    fi
  done <<< "$wireless_devices"
  
  # Asignar al array global
  PHYSICAL_ANDROID_DEVICES=("${physical_devices[@]}")
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
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # En macOS, usar AppleScript para activar ventanas del emulador
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
    
    # Intentar activar procesos específicos del emulador
    osascript -e 'tell application "System Events" to set frontmost of process "emulator" to true' 2>/dev/null || true
    osascript -e 'tell application "System Events" to set frontmost of process "qemu-system-x86_64" to true' 2>/dev/null || true
    osascript -e 'tell application "System Events" to set frontmost of process "qemu-system-aarch64" to true' 2>/dev/null || true
  fi
  
  sleep 2
}

# Función para matar el proceso que usa el puerto 8080
kill_port_8080() {
  local pid=$(lsof -ti:8080)
  if [ ! -z "$pid" ]; then
    echo -e "${YELLOW}🔄 Matando proceso $pid que usa el puerto 8080...${NC}"
    kill -9 $pid 2>/dev/null
    sleep 1
  fi
}

# Función mejorada para lanzar en dispositivo iOS con timeout
launch_ios_device() {
  local device_info="$1"
  local device_id=$(echo "$device_info" | cut -d':' -f1)
  local device_name=$(echo "$device_info" | cut -d':' -f2-)
  local delay_seconds="$2"
  
  # Aplicar delay escalonado para evitar conflictos de compilación
  if [ ! -z "$delay_seconds" ] && [ "$delay_seconds" -gt 0 ]; then
    echo -e "${ORANGE}⏳ Esperando ${delay_seconds}s antes de lanzar $device_name...${NC}"
    sleep "$delay_seconds"
  fi
  
  create_box "🍎 Lanzando iOS: $device_name" "$ORANGE"
  
  # Variable de control para el foco (solo una vez)
  local focus_applied=false
  local app_ready=false
  
  # Crear archivo de log para este dispositivo
  local log_file="/tmp/ios_log_${device_id}.txt"
  
  # Lanzar Flutter directamente sin procesamiento de salida complejo
  # El procesamiento de salida en tiempo real puede causar problemas con pipes
  flutter run -d "$device_id" --target "$FLUTTER_TARGET" 2>&1 | while IFS= read -r line; do
    echo -e "${ORANGE}[iOS: $device_name]${NC} $line"
    
    # Detectar cuando la app está a punto de abrirse y dar foco al simulador (SOLO UNA VEZ)
    if [[ "$focus_applied" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Xcode build done"* ]]); then
      echo -e "\n${ORANGE}🎯 Aplicación instalándose, dando foco al simulador...${NC}"
      export focus_applied=true
      focus_ios_simulator
    fi
    
    # Detectar cuando la app está lista (múltiples indicadores)
    if [[ "$app_ready" == false ]] && ([[ "$line" == *"To hot reload"* ]] || [[ "$line" == *"To hot restart"* ]] || [[ "$line" == *"Flutter run key commands"* ]] || [[ "$line" == *"A Dart VM Service on"* ]]); then
      echo -e "\n${ORANGE}✅ iOS listo: $device_name${NC}\n"
      export app_ready=true
      # Crear un archivo temporal para indicar que este dispositivo está listo
      touch "/tmp/ios_ready_${device_id}"
      echo -e "${ORANGE}📝 Archivo de estado creado: /tmp/ios_ready_${device_id}${NC}"
    fi
  done &
  
  # Guardar el PID del proceso para poder monitorearlo
  local flutter_pid=$!
  echo "$flutter_pid" > "/tmp/ios_pid_${device_id}"
  
  # Monitorear el proceso con timeout (iOS necesita más tiempo que Android)
  local timeout_count=0
  local max_timeout=180  # 180 segundos (3 minutos) para iOS - Xcode es lento
  
  while [ $timeout_count -lt $max_timeout ]; do
    if ! kill -0 $flutter_pid 2>/dev/null; then
      echo -e "${RED}❌ Proceso de Flutter terminó inesperadamente para $device_name${NC}"
      break
    fi
    
    if [ -f "/tmp/ios_ready_${device_id}" ]; then
      echo -e "${GREEN}✅ $device_name está listo y funcionando${NC}"
      break
    fi
    
    # Mostrar progreso cada 15 segundos para iOS
    if [ $((timeout_count % 15)) -eq 0 ] && [ $timeout_count -gt 0 ]; then
      echo -e "${ORANGE}⏳ iOS compilando... ${timeout_count}s transcurridos (Xcode puede tardar hasta 3 min)${NC}"
    fi
    
    sleep 1
    timeout_count=$((timeout_count + 1))
  done
  
  if [ $timeout_count -eq $max_timeout ]; then
    echo -e "${YELLOW}⚠️  Timeout alcanzado para $device_name, pero el proceso continúa${NC}"
  fi
}

# Función para lanzar en emulador Android
launch_android_emulator() {
  local device_info="$1"
  local device_id=$(echo "$device_info" | cut -d':' -f1)
  local device_name=$(echo "$device_info" | cut -d':' -f2-)
  
  create_box "🤖 Lanzando Android: $device_name" "$GREEN"
  
  # Variable de control para el foco (solo una vez)
  local focus_applied=false
  local app_ready=false
  
  # Crear archivo de log para este dispositivo
  local log_file="/tmp/android_log_${device_id}.txt"
  
  # Función para procesar la salida de Flutter
  process_android_output() {
    while read line; do
      echo -e "${GREEN}[Android: $device_name]${NC} $line"
      echo "$line" >> "$log_file"
      
      local lower_line=$(echo "$line" | tr '[:upper:]' '[:lower:]')
      if [[ "$line" == *"Error: null"* ]] || [[ "$line" == *"Error null"* ]]; then
        continue
      fi
      # Detectar errores críticos
      if [[ "$lower_line" == *"error: null"* ]] || [[ "$lower_line" == *"error null"* ]]; then
        continue
      fi
      if [[ "$line" =~ (^|[^[:alpha:]])Error([[:space:][:punct:]]|$) ]] ||
         [[ "$line" =~ (^|[^[:alpha:]])ERROR([[:space:][:punct:]]|$) ]] ||
         [[ "$lower_line" == *" failed"* ]] ||
         [[ "$lower_line" == *" exception"* ]]; then
        echo -e "${RED}❌ [Android: $device_name] Error detectado: $line${NC}"
      fi
      
      # Detectar cuando la app está a punto de abrirse y dar foco al emulador (SOLO UNA VEZ)
      if [[ "$focus_applied" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing APK"* ]]); then
        echo -e "\n${GREEN}🎯 [Android: $device_name] Aplicación instalándose, dando foco al emulador...${NC}"
        
        # Marcar que ya se aplicó el foco
        focus_applied=true
        focus_android_emulator
      fi
      
      # Detectar cuando la app está lista (múltiples indicadores)
      if [[ "$app_ready" == false ]] && ([[ "$line" == *"To hot reload"* ]] || [[ "$line" == *"To hot restart"* ]] || [[ "$line" == *"Running with sound null safety"* ]] || [[ "$line" == *"Flutter run key commands"* ]]); then
        echo -e "\n${GREEN}✅ [Android: $device_name] Aplicación lista${NC}\n"
        app_ready=true
        # Crear un archivo temporal para indicar que este dispositivo está listo
        touch "/tmp/android_ready_${device_id}"
        echo -e "${GREEN}📝 Archivo de estado creado: /tmp/android_ready_${device_id}${NC}"
      fi
    done
  }
  
  # Lanzar Flutter en background con procesamiento de salida
  flutter run -d "$device_id" --target "$FLUTTER_TARGET" 2>&1 | process_android_output &
  
  # Guardar el PID del proceso para poder monitorearlo
  local flutter_pid=$!
  echo "$flutter_pid" > "/tmp/android_pid_${device_id}"
  
  # Monitorear el proceso con timeout
  local timeout_count=0
  local max_timeout=60  # 60 segundos máximo
  
  while [ $timeout_count -lt $max_timeout ]; do
    if ! kill -0 $flutter_pid 2>/dev/null; then
      echo -e "${RED}❌ Proceso de Flutter terminó inesperadamente para $device_name${NC}"
      break
    fi
    
    if [ -f "/tmp/android_ready_${device_id}" ]; then
      echo -e "${GREEN}✅ $device_name está listo y funcionando${NC}"
      break
    fi
    
    sleep 1
    timeout_count=$((timeout_count + 1))
  done
  
  if [ $timeout_count -eq $max_timeout ]; then
    echo -e "${YELLOW}⚠️  Timeout alcanzado para $device_name, pero el proceso continúa${NC}"
  fi
}

# Función para lanzar en dispositivo Android físico
launch_physical_android() {
  local device_info="$1"
  local device_id=$(echo "$device_info" | cut -d':' -f1)
  local device_name=$(echo "$device_info" | cut -d':' -f2-)
  
  create_box "📱 Lanzando Android Físico: $device_name" "$GREEN"
  
  # Variable de control para el foco (solo una vez)
  local focus_applied=false
  local app_ready=false
  
  # Crear archivo de log para este dispositivo
  local log_file="/tmp/android_log_${device_id}.txt"
  
  # Función para procesar la salida de Flutter
  process_physical_android_output() {
    while read line; do
      echo -e "${GREEN}[Android Físico: $device_name]${NC} $line"
      echo "$line" >> "$log_file"
      
      local lower_line=$(echo "$line" | tr '[:upper:]' '[:lower:]')
      if [[ "$line" == *"Error: null"* ]] || [[ "$line" == *"Error null"* ]]; then
        continue
      fi
      # Detectar errores críticos
      if [[ "$lower_line" == *"error: null"* ]] || [[ "$lower_line" == *"error null"* ]]; then
        continue
      fi
      if [[ "$line" =~ (^|[^[:alpha:]])Error([[:space:][:punct:]]|$) ]] ||
         [[ "$line" =~ (^|[^[:alpha:]])ERROR([[:space:][:punct:]]|$) ]] ||
         [[ "$lower_line" == *" failed"* ]] ||
         [[ "$lower_line" == *" exception"* ]]; then
        echo -e "${RED}❌ [Android Físico: $device_name] Error detectado: $line${NC}"
      fi
      
      # Detectar cuando la app está lista (múltiples indicadores)
      if [[ "$app_ready" == false ]] && ([[ "$line" == *"To hot reload"* ]] || [[ "$line" == *"To hot restart"* ]] || [[ "$line" == *"Running with sound null safety"* ]] || [[ "$line" == *"Flutter run key commands"* ]]); then
        echo -e "\n${GREEN}✅ [Android Físico: $device_name] Aplicación lista${NC}\n"
        app_ready=true
        # Crear un archivo temporal para indicar que este dispositivo está listo
        touch "/tmp/android_ready_${device_id}"
        echo -e "${GREEN}📝 Archivo de estado creado: /tmp/android_ready_${device_id}${NC}"
      fi
    done
  }
  
  # Lanzar Flutter en background con procesamiento de salida
  flutter run -d "$device_id" --target "$FLUTTER_TARGET" 2>&1 | process_physical_android_output &
  
  # Guardar el PID del proceso para poder monitorearlo
  local flutter_pid=$!
  echo "$flutter_pid" > "/tmp/android_pid_${device_id}"
  
  # Monitorear el proceso con timeout
  local timeout_count=0
  local max_timeout=60  # 60 segundos máximo
  
  while [ $timeout_count -lt $max_timeout ]; do
    if ! kill -0 $flutter_pid 2>/dev/null; then
      echo -e "${RED}❌ Proceso de Flutter terminó inesperadamente para $device_name${NC}"
      break
    fi
    
    if [ -f "/tmp/android_ready_${device_id}" ]; then
      echo -e "${GREEN}✅ $device_name está listo y funcionando${NC}"
      break
    fi
    
    sleep 1
    timeout_count=$((timeout_count + 1))
  done
  
  if [ $timeout_count -eq $max_timeout ]; then
    echo -e "${YELLOW}⚠️  Timeout alcanzado para $device_name, pero el proceso continúa${NC}"
  fi
}

# Función para monitorear el progreso de todos los dispositivos
monitor_progress() {
  echo -e "\n${BLUE}📊 Monitoreando progreso de dispositivos...${NC}"
  
  local total_ios=${#IOS_DEVICES[@]}
  local total_android=${#ANDROID_DEVICES[@]}
  local total_physical=${#PHYSICAL_ANDROID_DEVICES[@]}
  local total_devices=$((total_ios + total_android + total_physical))
  
  local ready_ios=0
  local ready_android=0
  local ready_physical=0
  local max_wait_time=120  # Máximo 2 minutos de espera
  local elapsed_time=0
  
  echo -e "${BLUE}⏱️  Tiempo máximo de espera: ${max_wait_time}s${NC}"
  echo -e "${BLUE}📱 Dispositivos totales: iOS: $total_ios | Android: $total_android | Físicos: $total_physical${NC}"
  
  # Monitorear hasta que todos los dispositivos estén listos o se agote el tiempo
  while [ $elapsed_time -lt $max_wait_time ]; do
    ready_ios=0
    ready_android=0
    ready_physical=0
    
    # Verificar archivos de estado iOS
    for device in "${IOS_DEVICES[@]}"; do
      local device_id=$(echo "$device" | cut -d':' -f1)
      if [ -f "/tmp/ios_ready_${device_id}" ]; then
        ready_ios=$((ready_ios + 1))
      fi
    done
    
    # Verificar archivos de estado Android
    for device in "${ANDROID_DEVICES[@]}"; do
      local device_id=$(echo "$device" | cut -d':' -f1)
      if [ -f "/tmp/android_ready_${device_id}" ]; then
        ready_android=$((ready_android + 1))
      fi
    done
    
    # Verificar archivos de estado Android físicos
    for device in "${PHYSICAL_ANDROID_DEVICES[@]}"; do
      local device_id=$(echo "$device" | cut -d':' -f1)
      if [ -f "/tmp/android_ready_${device_id}" ]; then
        ready_physical=$((ready_physical + 1))
      fi
    done
    
    local total_ready=$((ready_ios + ready_android + ready_physical))
    
    # Mostrar progreso
    if [ $total_ready -lt $total_devices ]; then
      echo -e "${YELLOW}⏳ Progreso: ${total_ready}/${total_devices} dispositivos listos (${elapsed_time}s/${max_wait_time}s)${NC}"
      echo -e "${BLUE}  📱 iOS: ${ready_ios}/${total_ios} | 🤖 Android: ${ready_android}/${total_android} | 📱 Físicos: ${ready_physical}/${total_physical}${NC}"
      sleep 5
      elapsed_time=$((elapsed_time + 5))
    else
      break
    fi
  done
  
  # Verificar si se completó o se agotó el tiempo
  if [ $total_ready -eq $total_devices ]; then
    echo -e "${GREEN}🎉 ¡Todos los dispositivos están listos!${NC}"
  else
    echo -e "${YELLOW}⚠️  Tiempo de espera agotado. Algunos dispositivos pueden no estar completamente listos.${NC}"
    echo -e "${BLUE}💡 Las apps deberían estar funcionando en los dispositivos.${NC}"
  fi
  
  # Limpiar archivos temporales
  for device in "${IOS_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    rm -f "/tmp/ios_ready_${device_id}" 2>/dev/null || true
    rm -f "/tmp/ios_pid_${device_id}" 2>/dev/null || true
  done
  
  for device in "${ANDROID_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    rm -f "/tmp/android_ready_${device_id}" 2>/dev/null || true
    rm -f "/tmp/android_pid_${device_id}" 2>/dev/null || true
  done
  
  for device in "${PHYSICAL_ANDROID_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    rm -f "/tmp/android_ready_${device_id}" 2>/dev/null || true
    rm -f "/tmp/android_pid_${device_id}" 2>/dev/null || true
  done
}

# Función para lanzar en Web
launch_web() {
  create_box "🖥 Lanzando Web" "$BLUE"
  
  # Matar proceso del puerto 8080 si existe
  kill_port_8080
  
  flutter run -d web-server --web-port=8080 --target "$FLUTTER_TARGET" | while read line; do
    echo -e "${BLUE}[Web]${NC} $line"
    local lower_line=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    if [[ "$line" == *"Error: null"* ]] || [[ "$line" == *"Error null"* ]]; then
      continue
    fi
    
    # Detectar errores críticos
    if [[ "$lower_line" == *"error: null"* ]] || [[ "$lower_line" == *"error null"* ]]; then
      continue
    fi
    if [[ "$line" =~ (^|[^[:alpha:]])Error([[:space:][:punct:]]|$) ]] ||
       [[ "$line" =~ (^|[^[:alpha:]])ERROR([[:space:][:punct:]]|$) ]] ||
       [[ "$lower_line" == *" failed"* ]] ||
       [[ "$lower_line" == *" exception"* ]]; then
      echo -e "${RED}❌ [Web] Error detectado: $line${NC}"
    fi
    
    if [[ "$line" == *"Serving DevTools at"* ]] || [[ "$line" == *"The Flutter DevTools debugger and profiler on the Web is available at:"* ]] || [[ "$line" == *"Running with sound null safety"* ]] || [[ "$line" == *"lib/main.dart is being served at"* ]] || [[ "$line" == *"lib/bootstrap.dart is being served at"* ]] || [[ "$line" == *"Serving at http://localhost:8080"* ]] || [[ "$line" == *"To hot restart"* ]]; then
      echo -e "\n${BLUE}✅ [Web] Aplicación lista: http://localhost:8080${NC}\n"
    fi
  done &
}

# Función para limpiar archivos temporales antiguos
cleanup_old_files() {
  echo -e "${BLUE}🧹 Limpiando archivos temporales antiguos...${NC}"
  rm -f /tmp/ios_ready_* 2>/dev/null || true
  rm -f /tmp/ios_pid_* 2>/dev/null || true
  rm -f /tmp/android_ready_* 2>/dev/null || true
  rm -f /tmp/android_pid_* 2>/dev/null || true
  rm -f /tmp/ios_log_* 2>/dev/null || true
  rm -f /tmp/android_log_* 2>/dev/null || true
  echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Función principal de detección y lanzamiento
main() {
  echo -e "${YELLOW}🔍 Iniciando detección automática de dispositivos...${NC}"
  
  # Limpiar archivos temporales antiguos
  cleanup_old_files
  
  # Detectar todos los tipos de dispositivos
  detect_ios_simulators
  detect_android_emulators
  detect_physical_android
  
  # Contar total de dispositivos detectados (solo iOS y Android)
  local total_devices=0
  total_devices=$(( ${#IOS_DEVICES[@]} + ${#ANDROID_DEVICES[@]} + ${#PHYSICAL_ANDROID_DEVICES[@]} ))
  
  if [ $total_devices -eq 0 ]; then
    echo -e "${RED}❌ No se detectaron dispositivos iOS o Android activos${NC}"
    echo -e "${YELLOW}💡 Asegúrate de tener al menos un simulador/emulador ejecutándose${NC}"
    exit 1
  fi
  
  echo -e "\n${GREEN}🎯 Total de dispositivos detectados: $total_devices${NC}"
  echo -e "${BLUE}📱 iOS: ${#IOS_DEVICES[@]} | 🤖 Android: ${#ANDROID_DEVICES[@]} | 📱 Físico: ${#PHYSICAL_ANDROID_DEVICES[@]}${NC}"
  
  # Lanzar en todos los dispositivos iOS SECUENCIALMENTE para evitar conflictos de Xcode
  local ios_count=0
  for device in "${IOS_DEVICES[@]}"; do
    ios_count=$((ios_count + 1))
    echo -e "${ORANGE}📱 Lanzando iOS ${ios_count}/${#IOS_DEVICES[@]}: $(echo "$device" | cut -d':' -f2-)${NC}"
    launch_ios_device "$device" "0"

    # Esperar a que este dispositivo esté completamente listo antes del siguiente
    if [ $ios_count -lt ${#IOS_DEVICES[@]} ]; then
      echo -e "${ORANGE}⏳ Esperando a que $device termine de compilar antes del siguiente...${NC}"
      local device_id=$(echo "$device" | cut -d':' -f1)
      local wait_count=0
      local max_wait=240  # 4 minutos - iOS necesita más tiempo con Xcode
      local pid_file="/tmp/ios_pid_${device_id}"
      while [ $wait_count -lt $max_wait ]; do
        if [ -f "/tmp/ios_ready_${device_id}" ]; then
          echo -e "${GREEN}✅ $device está listo, continuando con el siguiente...${NC}"
          break
        fi

        if [ -f "$pid_file" ]; then
          local running_pid=$(cat "$pid_file" 2>/dev/null)
          if [ -z "$running_pid" ] || ! kill -0 "$running_pid" 2>/dev/null; then
            echo -e "${RED}❌ Flutter terminó antes de completar $device. Continuando con el siguiente simulador...${NC}"
            break
          fi
        fi

        sleep 2
        wait_count=$((wait_count + 2))

        # Mostrar progreso cada 30 segundos
        if [ $((wait_count % 30)) -eq 0 ]; then
          echo -e "${YELLOW}⏳ Esperando... (${wait_count}s/${max_wait}s) - Xcode compilando...${NC}"
        fi
      done

      if [ $wait_count -eq $max_wait ]; then
        if [ -f "/tmp/ios_ready_${device_id}" ]; then
          echo -e "${GREEN}✅ Timeout alcanzado pero $device reportó estar listo, continuando...${NC}"
        else
          echo -e "${YELLOW}⚠️  Timeout esperando a $device y sin confirmación de estado. Continuando de todos modos...${NC}"
        fi
      fi
    fi
  done
  
  # Lanzar en todos los emuladores Android
  for device in "${ANDROID_DEVICES[@]}"; do
    launch_android_emulator "$device"
    sleep 2  # Pequeña pausa entre lanzamientos
  done
  
  # Lanzar en todos los dispositivos Android físicos
  for device in "${PHYSICAL_ANDROID_DEVICES[@]}"; do
    launch_physical_android "$device"
    sleep 2  # Pequeña pausa entre lanzamientos
  done
  
  # Web removido - solo iOS y Android
  
  echo -e "\n${YELLOW}🚀 Todos los dispositivos han sido lanzados${NC}"
  echo -e "${BLUE}💡 Usa 'Ctrl+C' para detener todos los procesos${NC}"
  
  # Esperar un poco antes de empezar a monitorear para dar tiempo a que los dispositivos se inicialicen
  echo -e "${BLUE}⏳ Esperando 20s antes de monitorear el progreso...${NC}"
  sleep 20
  
  # Debug: verificar archivos de estado antes de monitorear
  echo -e "\n${BLUE}🔍 Debug: Verificando archivos de estado...${NC}"
  
  # Verificar iOS
  for device in "${IOS_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    local device_name=$(echo "$device" | cut -d':' -f2-)
    if [ -f "/tmp/ios_ready_${device_id}" ]; then
      echo -e "${GREEN}✅ Archivo encontrado para $device_name: /tmp/ios_ready_${device_id}${NC}"
    else
      echo -e "${YELLOW}⚠️  Archivo NO encontrado para $device_name: /tmp/ios_ready_${device_id}${NC}"
    fi
  done
  
  # Verificar Android
  for device in "${ANDROID_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    local device_name=$(echo "$device" | cut -d':' -f2-)
    if [ -f "/tmp/android_ready_${device_id}" ]; then
      echo -e "${GREEN}✅ Archivo encontrado para $device_name: /tmp/android_ready_${device_id}${NC}"
    else
      echo -e "${YELLOW}⚠️  Archivo NO encontrado para $device_name: /tmp/android_ready_${device_id}${NC}"
    fi
  done
  
  # Verificar Android físicos
  for device in "${PHYSICAL_ANDROID_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    local device_name=$(echo "$device" | cut -d':' -f2-)
    if [ -f "/tmp/android_ready_${device_id}" ]; then
      echo -e "${GREEN}✅ Archivo encontrado para $device_name: /tmp/android_ready_${device_id}${NC}"
    else
      echo -e "${YELLOW}⚠️  Archivo NO encontrado para $device_name: /tmp/android_ready_${device_id}${NC}"
    fi
  done
  
  # Monitorear el progreso de todos los dispositivos
  monitor_progress
  
  # Esperar a que todos los procesos terminen
  wait
}

# Función de limpieza al salir
cleanup() {
  echo -e "\n${BLUE}🧹 Limpiando procesos...${NC}"
  
  # Matar procesos específicos de iOS por PID
  for device in "${IOS_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    if [ -f "/tmp/ios_pid_${device_id}" ]; then
      local pid=$(cat "/tmp/ios_pid_${device_id}")
      if [ ! -z "$pid" ]; then
        echo -e "${ORANGE}🔄 Matando proceso iOS $pid...${NC}"
        kill -9 "$pid" 2>/dev/null || true
      fi
      rm -f "/tmp/ios_pid_${device_id}" 2>/dev/null || true
    fi
    rm -f "/tmp/ios_ready_${device_id}" 2>/dev/null || true
  done
  
  # Matar procesos específicos de Android por PID
  for device in "${ANDROID_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    if [ -f "/tmp/android_pid_${device_id}" ]; then
      local pid=$(cat "/tmp/android_pid_${device_id}")
      if [ ! -z "$pid" ]; then
        echo -e "${GREEN}🔄 Matando proceso Android $pid...${NC}"
        kill -9 "$pid" 2>/dev/null || true
      fi
      rm -f "/tmp/android_pid_${device_id}" 2>/dev/null || true
    fi
    rm -f "/tmp/android_ready_${device_id}" 2>/dev/null || true
  done
  
  # Matar procesos específicos de Android físicos por PID
  for device in "${PHYSICAL_ANDROID_DEVICES[@]}"; do
    local device_id=$(echo "$device" | cut -d':' -f1)
    if [ -f "/tmp/android_pid_${device_id}" ]; then
      local pid=$(cat "/tmp/android_pid_${device_id}")
      if [ ! -z "$pid" ]; then
        echo -e "${GREEN}🔄 Matando proceso Android Físico $pid...${NC}"
        kill -9 "$pid" 2>/dev/null || true
      fi
      rm -f "/tmp/android_pid_${device_id}" 2>/dev/null || true
    fi
    rm -f "/tmp/android_ready_${device_id}" 2>/dev/null || true
  done
  
  # Matar todos los procesos de Flutter restantes
  pkill -f "flutter run" 2>/dev/null || true
  
  # Desconectar dispositivos ADB si es necesario
  if command -v adb &> /dev/null; then
    adb kill-server 2>/dev/null || true
  fi
  
  echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Usar trap para manejar señales de interrupción y limpieza
trap cleanup EXIT
trap 'echo -e "\n${YELLOW}⚠️  Interrumpiendo ejecución...${NC}"; exit 0' INT TERM

# Ejecutar función principal
main
