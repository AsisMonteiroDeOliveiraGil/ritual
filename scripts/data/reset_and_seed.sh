#!/usr/bin/env bash
# Borra todos los datos de usuarios (Auth + Firestore), recrea usuarios de prueba
# y ejecuta el seed completo. Ejecutar desde la raíz del proyecto.
#
# Requisitos:
#   - firebase-service-account.json (raíz) o functions/serviceAccountKey.json
#   - Firebase Console: Autenticación > Sign-in method > Email/Password habilitado
#   - La colección "restaurants" no se borra; si está vacía, el seed usa fallbacks
#
# Usuarios: dev@thefinalburgerapp.test, customer1-3@thefinalburgerapp.test
# Contraseña: Test1234!

set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== 1/3 Borrando Auth + Firestore (usuarios y datos relacionados) ==="
node scripts/data/delete.js

echo ""
echo "=== 2/3 Creando usuarios de prueba (Auth + Firestore) ==="
node scripts/data/recreate_users.js

echo ""
echo "=== 3/3 Seed de datos (posts, reseñas, chats, follows, etc.) ==="
(cd functions && npm run s)

echo ""
echo "Listo. Puedes iniciar sesión con:"
echo "  dev@thefinalburgerapp.test / Test1234!"
echo "  customer1@thefinalburgerapp.test / Test1234!"
echo "  (y customer2, customer3 con la misma contraseña)"
