#!/bin/bash

echo "🔍 Verificando estado de índices de Firestore..."
echo ""

# Verificar si Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI no está instalado. Instálalo con: npm install -g firebase-tools"
    exit 1
fi

# Verificar si estamos en el directorio correcto
if [ ! -f "firebase.json" ]; then
    echo "❌ No estás en el directorio raíz del proyecto. Navega a la carpeta del proyecto."
    exit 1
fi

echo "📋 Listando índices actuales:"
firebase firestore:indexes

echo ""
echo "⏳ Para verificar el estado completo de los índices, visita:"
echo "https://console.firebase.google.com/project/thefinalburgerapp/firestore/indexes"
echo ""
echo "💡 Los índices pueden tardar desde minutos hasta horas en construirse."
echo "   Una vez completados, las notificaciones funcionarán correctamente."
