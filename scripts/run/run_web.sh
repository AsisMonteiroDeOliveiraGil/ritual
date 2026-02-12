#!/bin/bash

echo -ne "\033]0;run_web\007"

# Definición de colores
BLUE='\033[38;5;39m'  # Un azul más intenso y brillante
NC='\033[0m' # No Color

# Exportar la API Key de Google Maps desde el .env (en la raíz del proyecto)
if [ -f .env ]; then
  export WEB_API_KEY=$(grep WEB_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  echo -e "${BLUE}🔑 WEB_API_KEY exportada: ${WEB_API_KEY:0:10}...${NC}"
else
  echo -e "${BLUE}⚠️  Archivo .env no encontrado en la raíz. No se exportó WEB_API_KEY.${NC}"
fi

# Inyectar la clave de Google Maps desde .env antes de lanzar la web
./scripts/inject_env_web.sh

# Lanzando Web
echo -e "\n${BLUE}🌐 Lanzando en Web (Chrome, modo ventana visible)${NC}\n"
flutter run -d chrome --web-port=8080 | while read line; do
  echo -e "${BLUE}[Web]${NC} $line"
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${BLUE}✅ Web listo: Chrome${NC}\n"
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${BLUE}✅ Web listo: Chrome${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${BLUE}✅ Web listo: Chrome${NC}\n"
  fi
done 