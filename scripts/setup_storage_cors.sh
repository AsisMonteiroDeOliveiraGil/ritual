#!/bin/bash

# Script para configurar CORS en Firebase Storage
# Esto permite que las imágenes se carguen correctamente en navegadores web (especialmente Firefox)
# 
# Requisitos previos:
# 1. Google Cloud SDK instalado (https://cloud.google.com/sdk/docs/install)
# 2. Autenticación con gcloud: gcloud auth login
# 3. Proyecto configurado: gcloud config set project thefinalburgerapp

set -e

echo "🔧 Configurando CORS para Firebase Storage..."
echo ""

# Verificar que gsutil esté instalado
if ! command -v gsutil &> /dev/null; then
    echo "❌ Error: gsutil no está instalado."
    echo ""
    echo "📦 Para instalar Google Cloud SDK:"
    echo "   macOS: brew install google-cloud-sdk"
    echo "   Linux: https://cloud.google.com/sdk/docs/install"
    echo "   Windows: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Verificar autenticación
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "⚠️  No hay cuentas autenticadas activas."
    echo "🔐 Ejecuta: gcloud auth login"
    exit 1
fi

# Verificar que el proyecto está configurado
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
if [ -z "$PROJECT_ID" ]; then
    echo "⚠️  No hay proyecto configurado."
    echo "🔧 Ejecuta: gcloud config set project thefinalburgerapp"
    exit 1
fi

echo "✅ Proyecto configurado: $PROJECT_ID"

# Nombre del bucket de Firebase Storage
BUCKET_NAME="thefinalburgerapp.firebasestorage.app"

# Verificar que el archivo cors.json existe
if [ ! -f "cors.json" ]; then
    echo "❌ Error: No se encontró el archivo cors.json"
    echo "💡 Asegúrate de ejecutar este script desde la raíz del proyecto"
    exit 1
fi

echo "📋 Configuración CORS a aplicar:"
cat cors.json
echo ""
echo "📤 Aplicando configuración CORS al bucket: $BUCKET_NAME"
echo ""

if gsutil cors set cors.json gs://$BUCKET_NAME; then
    echo ""
    echo "✅ Configuración CORS aplicada exitosamente"
    echo "🔄 Los cambios pueden tardar unos minutos en propagarse"
    echo ""
    echo "💡 Para verificar la configuración actual, ejecuta:"
    echo "   gsutil cors get gs://$BUCKET_NAME"
else
    echo ""
    echo "❌ Error al aplicar la configuración CORS"
    echo "💡 Verifica que tengas permisos para modificar el bucket"
    exit 1
fi

