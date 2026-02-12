#!/bin/bash

# Script para guardar imagen de menú en la carpeta menus y copiarla a los emuladores

# Colores
BLUE='\033[38;5;39m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
NC='\033[0m'

# Verificar que se proporcionó una imagen
if [ -z "$1" ]; then
  echo -e "${YELLOW}⚠️  Uso: $0 <ruta_a_imagen>${NC}"
  echo -e "${BLUE}Ejemplo: $0 ~/Desktop/menu.jpg${NC}"
  exit 1
fi

IMAGE_PATH="$1"
IMAGE_NAME=$(basename "$IMAGE_PATH")
MENUS_DIR="menus"
TARGET_PATH="$MENUS_DIR/$IMAGE_NAME"

# Verificar que el archivo existe
if [ ! -f "$IMAGE_PATH" ]; then
  echo -e "${RED}❌ Error: No se encontró el archivo: $IMAGE_PATH${NC}"
  exit 1
fi

echo -e "${BLUE}📸 Guardando imagen de menú...${NC}"
echo -e "${BLUE}📁 Archivo: $IMAGE_NAME${NC}"

# Crear carpeta menus si no existe
mkdir -p "$MENUS_DIR"

# Copiar imagen a la carpeta menus
cp "$IMAGE_PATH" "$TARGET_PATH"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Imagen guardada en: $TARGET_PATH${NC}"
else
  echo -e "${RED}❌ Error al copiar la imagen${NC}"
  exit 1
fi

# Obtener lista de emuladores conectados
connected_devices=$(adb devices | grep 'emulator-' | awk '{print $1}')

if [ -z "$connected_devices" ]; then
  echo -e "${YELLOW}⚠️  No se encontraron emuladores activos.${NC}"
  echo -e "${BLUE}💡 La imagen se guardó en $TARGET_PATH pero no se pudo copiar a los emuladores.${NC}"
  exit 0
fi

emulator_count=$(echo "$connected_devices" | wc -l | xargs)
echo -e "${GREEN}✅ Encontrados $emulator_count emulador(es)${NC}"

# Copiar imagen a cada emulador Android
for device in $connected_devices; do
  echo -e "${BLUE}🤖 Copiando imagen a Android $device...${NC}"
  
  # Crear directorio Pictures si no existe
  adb -s "$device" shell mkdir -p /sdcard/Pictures
  
  # Copiar imagen al emulador
  adb -s "$device" push "$TARGET_PATH" /sdcard/Pictures/
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}  ✅ Imagen copiada a $device${NC}"
    
    # Escanear el archivo para que aparezca en la galería
    adb -s "$device" shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/$IMAGE_NAME > /dev/null 2>&1
    echo -e "${GREEN}  ✅ Imagen escaneada en la galería de $device${NC}"
  else
    echo -e "${RED}  ❌ Error al copiar imagen a $device${NC}"
  fi
done

# Copiar imagen a simuladores iOS
ios_simulators=$(xcrun simctl list devices | grep -i "booted" | grep -i "iphone" | awk -F'[()]' '{print $2}')

if [ -n "$ios_simulators" ]; then
  ios_count=$(echo "$ios_simulators" | wc -l | xargs)
  echo -e "${GREEN}✅ Encontrados $ios_count simulador(es) iOS${NC}"
  
  for simulator_id in $ios_simulators; do
    echo -e "${BLUE}🍎 Copiando imagen a iOS simulador $simulator_id...${NC}"
    
    # Usar xcrun simctl addphoto para añadir la foto a la galería
    xcrun simctl addphoto "$simulator_id" "$TARGET_PATH" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}  ✅ Imagen copiada a simulador iOS${NC}"
    else
      echo -e "${RED}  ❌ Error al copiar imagen a simulador iOS${NC}"
    fi
  done
else
  echo -e "${YELLOW}⚠️  No se encontraron simuladores iOS activos${NC}"
fi

echo -e "\n${GREEN}✅ Proceso completado${NC}"
echo -e "${BLUE}📁 Imagen guardada en: $TARGET_PATH${NC}"
echo -e "${BLUE}📱 Imagen disponible en la galería de los dispositivos${NC}"

