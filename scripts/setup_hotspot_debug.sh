#!/bin/bash

# Script para configurar debugging vía hotspot del Android
# Requiere conectar el Android por USB una vez

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "${BLUE}📱 Configurando debugging vía hotspot...${NC}\n"

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
  echo -e "${BLUE}💡 Verifica que estés conectado al hotspot del Android${NC}"
  exit 1
fi

echo -e "${BLUE}🌐 Gateway detectado: $GATEWAY${NC}"
echo -e "${BLUE}💡 Esta es la IP de tu Android cuando funciona como hotspot${NC}\n"

# Buscar dispositivo USB (no emulador)
USB_DEVICE=$(adb devices | grep -v "List" | grep "device$" | grep -v "emulator" | grep -v ":5555" | awk '{print $1}' | head -1)

if [ -z "$USB_DEVICE" ]; then
  echo -e "${YELLOW}⚠️  No se encontró dispositivo Android físico conectado por USB${NC}"
  echo -e "\n${BLUE}📋 Pasos a seguir:${NC}"
  echo -e "   1. Conecta tu Android físico por USB a tu Mac"
  echo -e "   2. Acepta el diálogo de 'Depuración USB' en tu Android"
  echo -e "   3. Vuelve a ejecutar este script: ./scripts/setup_hotspot_debug.sh"
  echo -e "\n${BLUE}💡 O ejecuta manualmente:${NC}"
  echo -e "   adb tcpip 5555"
  exit 1
fi

echo -e "${GREEN}✅ Dispositivo USB detectado: $USB_DEVICE${NC}"

# Obtener información del dispositivo
DEVICE_MODEL=$(adb -s "$USB_DEVICE" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
echo -e "${BLUE}📱 Modelo: $DEVICE_MODEL${NC}\n"

# Habilitar modo TCP/IP
echo -e "${BLUE}🔧 Habilitando modo TCP/IP en puerto 5555...${NC}"
adb -s "$USB_DEVICE" tcpip 5555

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ No se pudo habilitar modo TCP/IP${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Modo TCP/IP habilitado${NC}"
echo -e "${BLUE}💡 Ahora puedes desconectar el cable USB${NC}\n"

# Esperar un momento
sleep 2

# Conectar vía hotspot
echo -e "${BLUE}🔌 Conectando vía hotspot a $GATEWAY:5555...${NC}"
adb connect "$GATEWAY:5555"

sleep 2

# Verificar conexión
if adb devices | grep -q "$GATEWAY:5555.*device"; then
  echo -e "${GREEN}✅ ¡Conectado exitosamente vía hotspot!${NC}"
  echo -e "\n${BLUE}📝 Ahora puedes ejecutar:${NC}"
  echo -e "   ./scripts/run/run_physical_android.sh"
  echo -e "\n${GREEN}✅ Configuración completada${NC}"
else
  echo -e "${YELLOW}⚠️  No se pudo conectar automáticamente${NC}"
  echo -e "${BLUE}💡 Intenta manualmente:${NC}"
  echo -e "   adb connect $GATEWAY:5555"
  echo -e "\n${BLUE}💡 Verifica que:${NC}"
  echo -e "   - Tu Mac esté conectada al hotspot del Android"
  echo -e "   - El Android siga emitiendo el hotspot"
fi











