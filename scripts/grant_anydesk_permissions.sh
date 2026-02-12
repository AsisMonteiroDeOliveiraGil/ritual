#!/bin/bash

# Script para otorgar permisos adicionales a AnyDesk en Android
# Esto puede ayudar a reducir los diálogos de confirmación

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "${BLUE}🔧 Configurando permisos de AnyDesk en Android...${NC}"

# Verificar que ADB esté disponible
if ! command -v adb >/dev/null 2>&1; then
  if [ -d "$HOME/Library/Android/sdk/platform-tools" ]; then
    export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
  else
    echo -e "${RED}❌ ADB no está disponible. Instala Android SDK Platform Tools.${NC}"
    exit 1
  fi
fi

# Verificar que haya dispositivos conectados
DEVICES=$(adb devices | grep -v "List" | grep "device$" | awk '{print $1}')

if [ -z "$DEVICES" ]; then
  echo -e "${YELLOW}⚠️  No se encontraron dispositivos Android conectados${NC}"
  echo -e "${BLUE}💡 Conecta tu dispositivo o inicia un emulador y vuelve a ejecutar este script${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Dispositivos encontrados:${NC}"
echo "$DEVICES" | while read -r device; do
  echo -e "  - $device"
done

# ID del paquete de AnyDesk
ANYDESK_PACKAGE="com.anydesk.anydeskandroid"

# Otorgar permisos uno por uno
echo -e "\n${BLUE}🔐 Otorgando permisos a AnyDesk...${NC}"

for device in $DEVICES; do
  echo -e "\n${BLUE}📱 Configurando dispositivo: $device${NC}"
  
  # Verificar que AnyDesk esté instalado
  if ! adb -s "$device" shell pm list packages | grep -q "$ANYDESK_PACKAGE"; then
    echo -e "${YELLOW}⚠️  AnyDesk no está instalado en $device${NC}"
    continue
  fi
  
  # Otorgar permisos de accesibilidad (requiere configuración manual)
  echo -e "${BLUE}ℹ️  Permisos de accesibilidad deben configurarse manualmente:${NC}"
  echo -e "   Configuración > Accesibilidad > AnyDesk > Activar"
  
  # Otorgar permisos de superposición (overlay)
  adb -s "$device" shell appops set "$ANYDESK_PACKAGE" SYSTEM_ALERT_WINDOW allow
  
  # Otorgar permisos de notificaciones
  adb -s "$device" shell appops set "$ANYDESK_PACKAGE" POST_NOTIFICATION allow
  
  # Otorgar permisos de uso en segundo plano
  adb -s "$device" shell appops set "$ANYDESK_PACKAGE" RUN_IN_BACKGROUND allow
  
  # Otorgar permisos de inicio automático
  adb -s "$device" shell appops set "$ANYDESK_PACKAGE" START_FOREGROUND allow
  
  echo -e "${GREEN}✅ Permisos otorgados para $device${NC}"
done

echo -e "\n${BLUE}📝 Notas importantes:${NC}"
echo -e "1. El diálogo de 'Share your screen' es una protección de seguridad de Android"
echo -e "2. Aunque tengas acceso desatendido, Android puede requerir confirmación manual"
echo -e "3. Acepta el diálogo manualmente la primera vez - puede que no vuelva a aparecer"
echo -e "4. Configura manualmente el permiso de accesibilidad en:"
echo -e "   Configuración > Accesibilidad > AnyDesk > Activar"
echo -e "\n${GREEN}✅ Configuración completada${NC}"











