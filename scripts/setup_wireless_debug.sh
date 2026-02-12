#!/bin/bash

# Script para configurar debugging inalámbrico en Android
# Uso: ./scripts/setup_wireless_debug.sh

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "${BLUE}📱 Configurando debugging inalámbrico para Android...${NC}\n"

# Verificar que ADB esté disponible
if ! command -v adb >/dev/null 2>&1; then
  if [ -d "$HOME/Library/Android/sdk/platform-tools" ]; then
    export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
  else
    echo -e "${RED}❌ ADB no está disponible. Instala Android SDK Platform Tools.${NC}"
    exit 1
  fi
fi

# Verificar dispositivos conectados por USB
echo -e "${BLUE}🔍 Buscando dispositivos Android conectados por USB...${NC}"
USB_DEVICES=$(adb devices | grep -v "List" | grep "device$" | grep -v ":5555" | awk '{print $1}')

if [ -z "$USB_DEVICES" ]; then
  echo -e "${YELLOW}⚠️  No se encontraron dispositivos conectados por USB${NC}"
  echo -e "${BLUE}💡 Pasos para configurar:${NC}"
  echo -e "   1. Conecta tu dispositivo Android por USB"
  echo -e "   2. Habilita 'Depuración USB' en tu dispositivo:"
  echo -e "      Configuración > Opciones de desarrollador > Depuración USB"
  echo -e "   3. Acepta el diálogo de autorización en tu dispositivo"
  echo -e "   4. Vuelve a ejecutar este script"
  exit 1
fi

# Mostrar dispositivos encontrados
echo -e "${GREEN}✅ Dispositivos USB encontrados:${NC}"
for device in $USB_DEVICES; do
  device_model=$(adb -s "$device" shell getprop ro.product.model 2>/dev/null || echo "Unknown")
  echo -e "   - $device ($device_model)"
done

# Seleccionar el primer dispositivo
SELECTED_DEVICE=$(echo "$USB_DEVICES" | head -1)
echo -e "\n${BLUE}📱 Usando dispositivo: $SELECTED_DEVICE${NC}"

# Obtener IP del dispositivo
echo -e "\n${BLUE}🌐 Obteniendo IP del dispositivo...${NC}"
DEVICE_IP=$(adb -s "$SELECTED_DEVICE" shell ip route | awk '/wlan0/ {print $9}' | head -1)

if [ -z "$DEVICE_IP" ]; then
  # Intentar método alternativo
  DEVICE_IP=$(adb -s "$SELECTED_DEVICE" shell "ifconfig wlan0 | grep 'inet addr' | cut -d: -f2 | cut -d' ' -f1" 2>/dev/null | head -1)
fi

if [ -z "$DEVICE_IP" ]; then
  # Método más moderno para Android 10+
  DEVICE_IP=$(adb -s "$SELECTED_DEVICE" shell "ip -f inet addr show wlan0 | grep -oP 'inet \K[\d.]+'" 2>/dev/null | head -1)
fi

if [ -z "$DEVICE_IP" ]; then
  echo -e "${YELLOW}⚠️  No se pudo obtener la IP automáticamente${NC}"
  echo -e "${BLUE}💡 Ingresa la IP de tu dispositivo manualmente:${NC}"
  read -p "   IP del dispositivo: " DEVICE_IP
  
  if [ -z "$DEVICE_IP" ]; then
    echo -e "${RED}❌ IP no válida${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✅ IP detectada: $DEVICE_IP${NC}"
fi

# Habilitar debugging inalámbrico
echo -e "\n${BLUE}🔧 Habilitando debugging inalámbrico en puerto 5555...${NC}"
adb -s "$SELECTED_DEVICE" tcpip 5555

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ No se pudo habilitar debugging inalámbrico${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Debugging inalámbrico habilitado${NC}"

# Esperar un momento
sleep 2

# Conectar inalámbricamente
echo -e "\n${BLUE}🔌 Conectando inalámbricamente a $DEVICE_IP:5555...${NC}"
adb connect "$DEVICE_IP:5555"

sleep 2

# Verificar conexión
if adb devices | grep -q "$DEVICE_IP:5555.*device"; then
  echo -e "${GREEN}✅ Conexión inalámbrica establecida exitosamente${NC}"
  echo -e "\n${BLUE}📝 Información:${NC}"
  echo -e "   - IP: $DEVICE_IP:5555"
  echo -e "   - Ahora puedes desconectar el cable USB"
  echo -e "   - Para lanzar la app: ./scripts/run/run_physical_android.sh"
  echo -e "\n${GREEN}✅ Configuración completada${NC}"
else
  echo -e "${YELLOW}⚠️  La conexión puede no estar completamente establecida${NC}"
  echo -e "${BLUE}💡 Verifica que:${NC}"
  echo -e "   - Tu dispositivo y tu Mac estén en la misma red WiFi"
  echo -e "   - El firewall no esté bloqueando el puerto 5555"
  echo -e "   - Intenta ejecutar: adb connect $DEVICE_IP:5555"
fi











