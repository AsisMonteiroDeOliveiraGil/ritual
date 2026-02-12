#!/bin/bash

echo -e "\033[38;5;39m📝 Cambiando títulos usando método alternativo...\033[0m"

# Método alternativo: usar Chrome DevTools Protocol
echo -e "\033[38;5;226m⚠️  IMPORTANTE: Para cambiar títulos necesitas activar JavaScript en Chrome:\033[0m"
echo -e "\033[38;5;226m   1. Ve a Chrome > Ver > Opciones para desarrolladores\033[0m"
echo -e "\033[38;5;226m   2. Activa 'Permitir JavaScript desde Eventos de Apple'\033[0m"
echo -e "\033[38;5;226m   3. Luego ejecuta este script nuevamente\033[0m"
echo ""

# Intentar método alternativo usando Chrome DevTools
echo -e "\033[38;5;39m🔄 Intentando método alternativo...\033[0m"

# Buscar puertos de debugging
DEBUG_PORTS=$(ps aux | grep "remote-debugging-port" | grep -E "(8080|8081)" | head -2)

if [ -n "$DEBUG_PORTS" ]; then
    echo -e "\033[38;5;46m✅ Encontrados puertos de debugging\033[0m"
    
    # Extraer puertos de debugging
    PORT_8080=$(echo "$DEBUG_PORTS" | grep "8080" | sed 's/.*remote-debugging-port=\([0-9]*\).*/\1/')
    PORT_8081=$(echo "$DEBUG_PORTS" | grep "8081" | sed 's/.*remote-debugging-port=\([0-9]*\).*/\1/')
    
    if [ -n "$PORT_8080" ]; then
        echo -e "\033[38;5;39m📱 Cambiando título para iPhone (puerto debug: $PORT_8080)...\033[0m"
        # Usar Chrome DevTools Protocol para cambiar título
        curl -s "http://localhost:$PORT_8080/json" | jq -r '.[0].id' | head -1 | xargs -I {} curl -s -X POST "http://localhost:$PORT_8080/json/runtime/evaluate" -H "Content-Type: application/json" -d '{"expression": "document.title = \"iPhone - The Final Burger\""}' > /dev/null 2>&1
    fi
    
    if [ -n "$PORT_8081" ]; then
        echo -e "\033[38;5;39m📱 Cambiando título para Android (puerto debug: $PORT_8081)...\033[0m"
        curl -s "http://localhost:$PORT_8081/json" | jq -r '.[0].id' | head -1 | xargs -I {} curl -s -X POST "http://localhost:$PORT_8081/json/runtime/evaluate" -H "Content-Type: application/json" -d '{"expression": "document.title = \"Android - The Final Burger\""}' > /dev/null 2>&1
    fi
    
    echo -e "\033[38;5;46m✅ Títulos cambiados usando Chrome DevTools Protocol\033[0m"
else
    echo -e "\033[38;5;226m⚠️  No se encontraron puertos de debugging activos\033[0m"
fi

echo -e "\033[38;5;39m📱 URLs disponibles:\033[0m"
echo -e "\033[38;5;226m   iPhone: http://localhost:8080\033[0m"
echo -e "\033[38;5;226m   Android: http://localhost:8081\033[0m"
