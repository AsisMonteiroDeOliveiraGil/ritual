#!/bin/bash

# Script para ejecutar Flutter en dispositivo Android físico inalámbrico
# Uso: ./scripts/run_physical_android.sh

# Definición de colores
GREEN='\033[38;5;46m'  # Verde intenso para Android Simulado
PHYSICAL_GREEN='\033[38;5;35m'  # Verde esmeralda para Android Físico
YELLOW='\033[38;5;226m'  # Amarillo para advertencias
RED='\033[38;5;196m'  # Rojo para errores
BLUE='\033[38;5;39m'  # Azul para información
NC='\033[0m' # No Color

echo -e "${PHYSICAL_GREEN}📱 Iniciando lanzamiento en dispositivo Android físico inalámbrico...${NC}"

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

# Verificar que ADB esté disponible
if ! command -v adb &> /dev/null; then
  # Intentar agregar Android SDK al PATH
  if [ -d "$HOME/Library/Android/sdk/platform-tools" ]; then
    export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
    echo -e "${BLUE}🔧 ADB agregado al PATH desde Android SDK${NC}"
  else
    echo -e "${RED}❌ Error: ADB no está disponible. Instala Android SDK Platform Tools.${NC}"
    exit 1
  fi
fi

# Verificar que el servidor ADB esté funcionando
echo -e "${BLUE}🔍 Verificando servidor ADB...${NC}"
adb start-server >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error: No se pudo iniciar el servidor ADB${NC}"
  exit 1
fi

# Función para verificar dispositivos inalámbricos
check_wireless_devices() {
  local wireless_devices=$(adb devices | grep ":5555" | wc -l)
  if [ $wireless_devices -eq 0 ]; then
    return 1
  fi
  return 0
}

# Función para obtener el primer dispositivo inalámbrico
get_wireless_device() {
  adb devices | grep ":5555" | head -1 | awk '{print $1}'
}

# Verificar conectividad de red
echo -e "\n${BLUE}🌐 Verificando conectividad de red...${NC}"
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  Advertencia: No hay conectividad a internet${NC}"
  echo -e "${BLUE}💡 Esto puede afectar algunas funcionalidades de la app${NC}"
else
  echo -e "${GREEN}✅ Conectividad de red verificada${NC}"
fi

# Verificar si hay dispositivos inalámbricos conectados
echo -e "\n${BLUE}🔍 Verificando dispositivos inalámbricos...${NC}"

if ! check_wireless_devices; then
  echo -e "${YELLOW}⚠️  No hay dispositivos inalámbricos conectados${NC}"
  echo -e "${BLUE}💡 Intentando conectar al dispositivo configurado...${NC}"
  
  # Intentar conectar al dispositivo que configuramos antes
  device_ip="192.168.1.218"
  echo -e "${BLUE}🔌 Conectando a $device_ip:5555...${NC}"
  
  # Verificar que la IP sea accesible antes de conectar
  if ping -c 1 "$device_ip" >/dev/null 2>&1; then
    adb connect $device_ip:5555
    
    # Verificar si la conexión fue exitosa
    sleep 2
    if ! check_wireless_devices; then
      echo -e "${RED}❌ No se pudo conectar al dispositivo inalámbrico${NC}"
      echo -e "${YELLOW}💡 Soluciones:${NC}"
      echo -e "   1. Verifica que tu dispositivo esté en la misma red WiFi"
      echo -e "   2. Ejecuta: adb tcpip 5555 (con dispositivo conectado por USB)"
      echo -e "   3. Luego: adb connect $device_ip:5555"
      exit 1
    fi
  else
    echo -e "${RED}❌ No se puede alcanzar la IP $device_ip${NC}"
    echo -e "${YELLOW}💡 Verifica que tu dispositivo esté en la misma red WiFi${NC}"
    exit 1
  fi
fi

# Obtener el dispositivo inalámbrico
wireless_device=$(get_wireless_device)
echo -e "${PHYSICAL_GREEN}✅ Dispositivo inalámbrico detectado: $wireless_device${NC}"

# Mostrar información del dispositivo
echo -e "\n${PHYSICAL_GREEN}📱 Dispositivo seleccionado: Dispositivo Android Físico${NC}"
echo -e "${PHYSICAL_GREEN}🆔 ID: $wireless_device${NC}"
echo -e "${PHYSICAL_GREEN}🌐 Conexión: Inalámbrica (WiFi)${NC}"

# Variable de control para el foco (solo una vez)
FOCUS_APPLIED=false

# Lanzando Android físico
echo -e "\n${PHYSICAL_GREEN}🤖 Lanzando en Android Físico ($wireless_device)${NC}"
echo -e "${PHYSICAL_GREEN}🔧 Usando API Key: ${ANDROID_API_KEY:0:10}...${NC}"
echo -e "${BLUE}💡 Recuerda: Tu dispositivo debe estar desbloqueado y visible${NC}\n"

# Función para manejar la salida de Flutter de manera más robusta
handle_flutter_output() {
  local app_ready=false
  local install_started=false
  
  while IFS= read -r line || [ -n "$line" ]; do
              # Solo mostrar líneas importantes, no todo el output
      if [[ "$line" == *"🎯"* ]] || [[ "$line" == *"✅"* ]] || [[ "$line" == *"Error"* ]] || [[ "$line" == *"Exception"* ]] || [[ "$line" == *"Failed"* ]] || [[ "$line" == *"Installing"* ]] || [[ "$line" == *"Syncing"* ]]; then
        echo -e "${PHYSICAL_GREEN}[Android Físico]${NC} $line"
      fi
    
                   # Detectar cuando la app está a punto de abrirse
      if [[ "$install_started" == false ]] && ([[ "$line" == *"Syncing files to device"* ]] || [[ "$line" == *"Installing build"* ]] || [[ "$line" == *"Installing APK"* ]]); then
        echo -e "\n${PHYSICAL_GREEN}🎯 Aplicación instalándose en tu dispositivo Android...${NC}"
        echo -e "${BLUE}💡 Verifica tu dispositivo móvil - la app se está instalando${NC}"
      
      # Marcar que ya se aplicó el foco
      install_started=true
      
      # En dispositivos físicos, no podemos dar foco a la ventana, pero podemos notificar
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # En macOS, mostrar notificación
        osascript -e 'display notification "Aplicación instalándose en tu dispositivo Android" with title "Flutter - Android Físico"' 2>/dev/null || true
      fi
      
      sleep 1
    fi
    
                   # Detectar cuando la app está lista
      if [[ "$app_ready" == false ]] && ([[ "$line" == *"To hot reload"* ]] || [[ "$line" == *"To hot restart"* ]] || [[ "$line" == *"Running with sound null safety"* ]] || [[ "$line" == *"Flutter run key commands"* ]]); then
        echo -e "\n${PHYSICAL_GREEN}✅ Android Físico listo: $wireless_device${NC}"
        echo -e "${BLUE}🎉 ¡Tu aplicación está ejecutándose en tu dispositivo Android!${NC}"
        echo -e "${BLUE}💡 Comandos disponibles:${NC}"
        echo -e "   - r: Hot reload"
        echo -e "   - R: Hot restart"
        echo -e "   - q: Salir"
        echo -e ""
        
        app_ready=true
      fi
    
    # Detectar errores de conexión
    if [[ "$line" == *"Lost connection to device"* ]]; then
      echo -e "\n${RED}❌ Conexión perdida con el dispositivo${NC}"
      echo -e "${YELLOW}💡 Posibles causas:${NC}"
      echo -e "   - Dispositivo se desconectó de WiFi"
      echo -e "   - Dispositivo entró en modo de ahorro de energía"
      echo -e "   - Problemas de red"
      echo -e "${BLUE}🔄 Para reconectar: adb connect $wireless_device${NC}\n"
    fi
    
    # Detectar cuando Flutter termina
    if [[ "$line" == *"Application finished."* ]] || [[ "$line" == *"Process finished"* ]]; then
      echo -e "\n${BLUE}🏁 Aplicación terminada${NC}"
      break
    fi
  done
}

# Lanzar Flutter con manejo robusto de la salida
echo -e "\n${PHYSICAL_GREEN}🤖 Lanzando en Android Físico ($wireless_device)${NC}"
echo -e "${PHYSICAL_GREEN}🔧 Usando API Key: ${ANDROID_API_KEY:0:10}...${NC}"
echo -e "${BLUE}💡 Recuerda: Tu dispositivo debe estar desbloqueado y visible${NC}\n"

# Función de limpieza al salir
cleanup() {
  echo -e "\n${BLUE}🧹 Limpiando conexiones...${NC}"
  # Desconectar dispositivos inalámbricos si es necesario
  if [ -n "$wireless_device" ]; then
    adb disconnect "$wireless_device" >/dev/null 2>&1 || true
  fi
  echo -e "${PHYSICAL_GREEN}✅ Limpieza completada${NC}"
}

# Usar trap para manejar señales de interrupción y limpieza
trap cleanup EXIT
trap 'echo -e "\n${YELLOW}⚠️  Interrumpiendo ejecución...${NC}"; exit 0' INT TERM

# Ejecutar Flutter y manejar la salida
if flutter run -d "$wireless_device" 2>&1 | handle_flutter_output; then
  echo -e "\n${PHYSICAL_GREEN}✅ Ejecución completada exitosamente${NC}"
else
  echo -e "\n${YELLOW}⚠️  La ejecución se interrumpió${NC}"
fi
