#!/bin/bash

# Script para descargar límites municipales reales desde OpenStreetMap
# Usa la API de Overpass para obtener GeoJSON de boundaries administrativos

BOUNDARIES_DIR="assets/boundaries"
mkdir -p "$BOUNDARIES_DIR"

echo "🗺️ Descargando límites municipales desde OpenStreetMap..."

# Las Rozas de Madrid (relation 345131)
echo "📍 Descargando Las Rozas de Madrid..."
curl -s "https://nominatim.openstreetmap.org/details.php?osmtype=R&osmid=345131&polygon_geojson=1&format=json" | \
  python3 -c "
import json
import sys
data = json.load(sys.stdin)
if 'geometry' in data:
    feature = {
        'type': 'Feature',
        'properties': {
            'name': 'Las Rozas de Madrid',
            'admin_level': '8',
            'boundary': 'administrative',
            'osm_id': 345131
        },
        'geometry': data['geometry']
    }
    print(json.dumps(feature, indent=2))
else:
    print('Error: No geometry found', file=sys.stderr)
    sys.exit(1)
" > "$BOUNDARIES_DIR/las_rozas.geojson"

if [ $? -eq 0 ]; then
    echo "✅ Las Rozas descargado correctamente"
else
    echo "❌ Error descargando Las Rozas"
fi

# Majadahonda (relation 345145) - para cuando se active
# echo "📍 Descargando Majadahonda..."
# curl -s "https://nominatim.openstreetmap.org/details.php?osmtype=R&osmid=345145&polygon_geojson=1&format=json" | \
#   python3 -c "..." > "$BOUNDARIES_DIR/majadahonda.geojson"

echo "🎉 Descarga completada"
echo ""
echo "Archivos generados:"
ls -la "$BOUNDARIES_DIR"/*.geojson 2>/dev/null || echo "No se encontraron archivos GeoJSON"
