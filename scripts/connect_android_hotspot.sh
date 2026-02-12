#!/bin/bash

# Script para conectar a Android cuando funciona como hotspot
# Uso: ./scripts/connect_android_hotspot.sh

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "${BLUE}📱 Conectando a Android vía hotspot...${NC}\n"

# Verificar ADB
if ! command -v adb >/dev/null 2>&1; then
  if [ -d "$HOME/Library/Android/sdk/platform-tools" ]; then
    export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
  else
    echo -e "${RED}❌ ADB no está disponible${NC}"
    exit 1
  fi
fi

# Obtener gateway (IP del Android cuando es hotspot)
GATEWAY=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}')

if [ -z "$GATEWAY" ]; then
  echo -e "${YELLOW}⚠️  No se pudo detectar el gateway${NC}"
  echo -e "${BLUE}💡 Verifica que estés conectado al WiFi del Android${NC}"
  exit 1
fi

echo -e "${BLUE}🌐 Gateway detectado: $GATEWAY${NC}"
echo -e "${BLUE}💡 Esta debería ser la IP de tu Android${NC}\n"

# Verificar si hay dispositivos USB conectados primero
USB_DEVICE=$(adb devices | grep -v "List" | grep "device$" | grep -v ":5555" | awk '{print $1}' | head -1)

if [ -n "$USB_DEVICE" ]; then
  echo -e "${GREEN}✅ Dispositivo USB detectado: $USB_DEVICE${NC}"
  echo -e "${BLUE}🔧 Habilitando debugging inalámbrico...${NC}"
  adb -s "$USB_DEVICE" tcpip 5555
  sleep 2
  echo -e "${GREEN}✅ Debugging inalámbrico habilitado${NC}"
  echo -e "${BLUE}💡 Ahora puedes desconectar el USB${NC}\n"
fi

# Intentar conectar
echo -e "${BLUE}🔌 Intentando conectar a $GATEWAY:5555...${NC}"
adb connect "$GATEWAY:5555"

sleep 2

# Verificar conexión
if adb devices | grep -q "$GATEWAY:5555.*device"; then
  echo -e "${GREEN}✅ ¡Conectado exitosamente a $GATEWAY:5555!${NC}"
  echo -e "\n${BLUE}📝 Ahora puedes ejecutar:${NC}"
  echo -e "   ./scripts/run/run_physical_android.sh"
  exit 0
else
  echo -e "${YELLOW}⚠️  No se pudo conectar automáticamente${NC}"
  echo -e "\n${BLUE}💡 Soluciones:${NC}"
  echo -e "   1. Conecta tu Android por USB una vez"
  echo -e "   2. Ejecuta: adb tcpip 5555"
  echo -e "   3. Desconecta el USB"
  echo -e "   4. Vuelve a ejecutar este script"
  echo -e "\n${BLUE}   O si tienes Android 11+:${NC}"
  echo -e "   1. Ve a: Configuración > Opciones de desarrollador"
  echo -e "   2. Activa 'Depuración inalámbrica'"
  echo -e "   3. Toca 'Depuración inalámbrica' y copia la IP:puerto"
  echo -e "   4. Ejecuta: adb connect IP:PUERTO"
  
  # Intentar detectar si hay Wireless Debugging activo
  echo -e "\n${BLUE}🔍 Buscando puertos de depuración inalámbrica...${NC}"
  for port in 5555 37000 37001 37002; do
    if timeout 1 bash -c "echo > /dev/tcp/$GATEWAY/$port" 2>/dev/null; then
      echo -e "${GREEN}✅ Puerto $port está abierto en $GATEWAY${NC}"
      echo -e "${BLUE}💡 Intentando: adb connect $GATEWAY:$port${NC}"
      adb connect "$GATEWAY:$port"
      sleep 2
      if adb devices | grep -q "$GATEWAY:$port.*device"; then
        echo -e "${GREEN}✅ ¡Conectado en puerto $port!${NC}"
        exit 0
      fi
    fi
  done
fi











