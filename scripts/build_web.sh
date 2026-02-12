#!/bin/bash

# Script para construir la aplicación web con configuración de entorno segura

# Función helper para imprimir con lolcat si está disponible
lol_echo() {
    if command -v lolcat &> /dev/null; then
        echo "$@" | lolcat
    else
        echo "$@"
    fi
}

lol_echo "🔧 Iniciando build de la aplicación web..."

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    lol_echo "❌ Error: No se encontró pubspec.yaml. Ejecuta este script desde la raíz del proyecto."
    exit 1
fi

# Crear archivo de configuración temporal para web
lol_echo "📝 Generando configuración de entorno para web..."

# Crear el archivo de configuración
cat > web/flutter_config.json << 'EOF'
{
  "ENVIRONMENT": "production",
  "ANDROID_API_KEY": "AIzaSyD-F7BYdsYkXWWxwgGvtkoZ-66i05t42Ts",
  "IOS_API_KEY": "AIzaSyBzE32sBSgniE6mUOtKt1ImwPJQrMtbYvk",
  "WEB_API_KEY": "AIzaSyAntpF0hc9UZNfUnjbi_VsVJyfYI9ko0YE",
  "BACKEND_API_KEY": "AIzaSyDRSxqFDuslHRj_CyFeaQF8Ph9dRP7uy9A",
  "ANDROID_APP_ID": "1:411608079775:android:9e54de315bdedc353171aa",
  "IOS_APP_ID": "1:411608079775:ios:78d71a85683e20493171aa",
  "IOS_CLIENT_ID": "411608079775-4jk98t3lb59kp90cf2ecud55fvspvjg7.apps.googleusercontent.com",
  "IOS_BUNDLE_ID": "com.thefinalburger.theFinalBurger",
  "API_KEY": "AIzaSyAABhiew48jPmW7offhcakmtVLCg_vZD1o",
  "AUTH_DOMAIN": "thefinalburgerapp.firebaseapp.com",
  "PROJECT_ID": "thefinalburgerapp",
  "STORAGE_BUCKET": "thefinalburgerapp.firebasestorage.app",
  "MESSAGING_SENDER_ID": "411608079775",
  "APP_ID": "1:411608079775:web:a574eb6bec1040263171aa",
  "MEASUREMENT_ID": "G-J6N6JPGCVM",
  "HUELLA_RELEASE": "16:8A:BD:1C:1A:4D:22:B3:04:2E:77:C5:F8:64:2B:20:D7:DE:D4:6A",
  "HUELLA_DEBUG": "B8:05:51:0F:8F:A9:C8:44:CE:E0:28:71:55:29:0E:9D:40:EE:85:F4",
  "APP_IDENTIFICADOR_ANDROID": "com.thefinalburger.the_final_burger",
  "APP_IDENTIFICADOR_IOS": "com.thefinalburger.theFinalBurger",
  "RESTRICCION_WEB": "https://thefinalburgerapp.web.app/*"
}
EOF

lol_echo "✅ Configuración generada en web/flutter_config.json"

# Limpiar build anterior
lol_echo "🧹 Limpiando build anterior..."
flutter clean

# Obtener dependencias
lol_echo "📦 Obteniendo dependencias..."
flutter pub get

# Construir para web en modo release
lol_echo "🏗️ Construyendo aplicación web..."
flutter build web --release --no-tree-shake-icons

# Verificar que el build fue exitoso
if [ $? -eq 0 ]; then
    lol_echo "✅ Build completado exitosamente"
    lol_echo "📁 Archivos generados en: build/web/"
    lol_echo "🚀 Para desplegar, ejecuta: firebase deploy --only hosting"
else
    lol_echo "❌ Error en el build"
    exit 1
fi 