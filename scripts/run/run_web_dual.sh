#!/bin/bash

echo -ne "\033]0;run_web_dual\007"

# Definición de colores
BLUE='\033[38;5;39m'  # Un azul más intenso y brillante
GREEN='\033[38;5;46m'  # Verde para éxito
YELLOW='\033[38;5;226m'  # Amarillo para advertencias
RED='\033[38;5;196m'  # Rojo para errores
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Lanzando aplicación web en DOS instancias de Chrome${NC}"

# Exportar la API Key de Google Maps desde el .env (en la raíz del proyecto)
if [ -f .env ]; then
  export WEB_API_KEY=$(grep WEB_API_KEY .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
  echo -e "${BLUE}🔑 WEB_API_KEY exportada: ${WEB_API_KEY:0:10}...${NC}"
else
  echo -e "${BLUE}⚠️  Archivo .env no encontrado en la raíz. No se exportó WEB_API_KEY.${NC}"
fi

# Inyectar la clave de Google Maps desde .env antes de lanzar la web
./scripts/inject_env_web.sh

# Función para matar procesos en puertos específicos
kill_port() {
  local port=$1
  echo -e "${YELLOW}🔍 Verificando puerto $port...${NC}"
  local pid=$(lsof -ti:$port 2>/dev/null)
  if [ ! -z "$pid" ]; then
    echo -e "${YELLOW}⚠️  Matando proceso en puerto $port (PID: $pid)${NC}"
    kill -9 $pid 2>/dev/null
    sleep 1
  else
    echo -e "${GREEN}✅ Puerto $port está libre${NC}"
  fi
}

# Matar procesos en los puertos que vamos a usar
kill_port 8080
kill_port 8081

echo -e "\n${BLUE}🚀 Iniciando primera instancia en puerto 8080...${NC}"

# Primera instancia en puerto 8080
flutter run -d chrome --web-port=8080 --web-hostname=localhost | while read line; do
  echo -e "${BLUE}[Chrome-1:8080]${NC} $line"
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${GREEN}✅ Primera instancia lista: Chrome en puerto 8080${NC}\n"
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${GREEN}✅ Primera instancia lista: Chrome en puerto 8080${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${GREEN}✅ Primera instancia lista: Chrome en puerto 8080${NC}\n"
  fi
done &

# Esperar un poco para que la primera instancia se inicie
sleep 3

echo -e "\n${BLUE}🚀 Iniciando segunda instancia en puerto 8081...${NC}"

# Segunda instancia en puerto 8081
flutter run -d chrome --web-port=8081 --web-hostname=localhost | while read line; do
  echo -e "${GREEN}[Chrome-2:8081]${NC} $line"
  if [[ "$line" == *"To hot reload"* || "$line" == *"To hot restart"* || "$line" == *"Application finished."* ]]; then
    echo -e "\n${GREEN}✅ Segunda instancia lista: Chrome en puerto 8081${NC}\n"
  fi
  if [[ "$line" == *"Running with sound null safety"* ]]; then
    echo -e "\n${GREEN}✅ Segunda instancia lista: Chrome en puerto 8081${NC}\n"
  fi
  if [[ "$line" == *"Syncing files to device"* ]]; then
    echo -e "\n${GREEN}✅ Segunda instancia lista: Chrome en puerto 8081${NC}\n"
  fi
done &

echo -e "\n${GREEN}🎉 Ambas instancias iniciadas:${NC}"
echo -e "${GREEN}   📱 Chrome 1: http://localhost:8080${NC}"
echo -e "${GREEN}   📱 Chrome 2: http://localhost:8081${NC}"
echo -e "\n${BLUE}💡 Puedes usar las herramientas de desarrollador de Chrome para simular diferentes dispositivos móviles${NC}"
echo -e "${BLUE}   F12 → Toggle device toolbar → Seleccionar diferentes dispositivos${NC}"

# Esperar a que ambos procesos terminen
wait
