#!/bin/bash

# Script para verificar el estado de Flutter y la conexión al dispositivo
# Uso: ./scripts/check_flutter_status.sh

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "${BLUE}📱 Verificando estado de Flutter y dispositivos...${NC}\n"

# 1. Verificar dispositivos ADB
echo -e "${BLUE}1️⃣ Dispositivos ADB conectados:${NC}"
adb devices
echo ""

# 2. Verificar dispositivos Flutter
echo -e "${BLUE}2️⃣ Dispositivos Flutter detectados:${NC}"
flutter devices 2>&1 | grep -E "(•|Found|192\.168)" || echo -e "${YELLOW}   No se encontraron dispositivos${NC}"
echo ""

# 3. Verificar procesos Flutter
echo -e "${BLUE}3️⃣ Procesos Flutter ejecutándose:${NC}"
FLUTTER_PROCESSES=$(ps aux | grep -i "flutter" | grep -v grep | grep -v "check_flutter_status")
if [ -z "$FLUTTER_PROCESSES" ]; then
  echo -e "${YELLOW}   No hay procesos Flutter ejecutándose${NC}"
else
  echo -e "${GREEN}   Procesos encontrados:${NC}"
  echo "$FLUTTER_PROCESSES"
fi
echo ""

# 4. Verificar conexión inalámbrica
echo -e "${BLUE}4️⃣ Conexión inalámbrica:${NC}"
WIRELESS_DEVICE=$(adb devices | grep ":5555" | awk '{print $1}')
if [ -z "$WIRELESS_DEVICE" ]; then
  echo -e "${RED}   ❌ No hay dispositivos inalámbricos conectados${NC}"
  echo -e "${YELLOW}   💡 Ejecuta: ./scripts/setup_wireless_debug.sh${NC}"
else
  echo -e "${GREEN}   ✅ Dispositivo inalámbrico: $WIRELESS_DEVICE${NC}"
  
  # Verificar si el dispositivo responde
  if ping -c 1 $(echo $WIRELESS_DEVICE | cut -d: -f1) >/dev/null 2>&1; then
    echo -e "${GREEN}   ✅ El dispositivo responde a ping${NC}"
  else
    echo -e "${YELLOW}   ⚠️  El dispositivo no responde a ping${NC}"
  fi
fi
echo ""

# 5. Verificar si hay apps instaladas recientemente
echo -e "${BLUE}5️⃣ Últimas apps instaladas en el dispositivo:${NC}"
if [ -n "$WIRELESS_DEVICE" ]; then
  adb -s "$WIRELESS_DEVICE" shell "pm list packages -3 | tail -5" 2>/dev/null || echo -e "${YELLOW}   No se pudo obtener la lista de apps${NC}"
else
  echo -e "${YELLOW}   No hay dispositivo conectado${NC}"
fi
echo ""

echo -e "${BLUE}💡 Para ver el log completo del proceso:${NC}"
echo -e "   tail -f /Users/asis/.cursor/projects/Users-asis-flutter-projects-the-final-burger/terminals/111718.txt"
echo ""
echo -e "${BLUE}💡 Para ejecutar la app manualmente:${NC}"
echo -e "   flutter run -d 192.168.1.151:5555"
