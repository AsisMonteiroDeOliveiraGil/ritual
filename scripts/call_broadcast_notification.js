#!/usr/bin/env node

/**
 * Script para enviar notificación broadcast después del despliegue
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Obtener argumentos de línea de comandos
const args = process.argv.slice(2);
const version = args[0] || '1.0.0';

// Salir silenciosamente si no está habilitado explícitamente
if (process.env.TFB_ENABLE_FCM_BROADCAST !== '1') {
    console.log('ℹ️ Broadcast FCM desactivado. Exporta TFB_ENABLE_FCM_BROADCAST=1 para habilitar.');
    process.exit(0);
}

// Inicializar Firebase Admin
// Construir la ruta al archivo desde el directorio raíz del proyecto
const scriptDir = __dirname;
const projectRoot = path.resolve(scriptDir, '..');
const serviceAccountPath = path.join(projectRoot, 'firebase-service-account.json');

if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ Error: No se encontró firebase-service-account.json en:', serviceAccountPath);
    process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

console.log('🔐 Usando cuenta de servicio:', serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

async function sendBroadcastNotification() {
    try {
        console.log('📢 Enviando notificación broadcast...');

        // Obtener todos los usuarios con token FCM
        const db = admin.firestore();
        const usersSnapshot = await db
            .collection('users')
            .where('fcmToken', '!=', null)
            .get();

        console.log(`📊 Usuarios encontrados con FCM: ${usersSnapshot.size}`);

        if (usersSnapshot.empty) {
            console.log('⚠️ No hay usuarios con token FCM');
            return;
        }

        const results = {
            total: usersSnapshot.size,
            successful: 0,
            failed: 0,
        };

        // Preparar el mensaje
        const titleText = '🍭 CODEX WEB 🍬';
        const bodyText = `🔥🚀 Nueva version v${version} 🚀🔥`;

        const message = {
            notification: {
                title: titleText,
                body: bodyText,
            },
            data: {
                type: 'broadcast',
                version: version,
                event: 'deployment',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'the_final_burger_channel',
                    priority: 'high',
                    color: '#FF6B35', // Color de la notificación (naranja/burguer theme)
                    icon: 'ic_notification',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    sound: 'laura', // Sonido personalizado de notificación
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                        category: 'CODEX_WEB_RELEASE',
                        'mutable-content': 1,
                    },
                },
            },
            webpush: {
                headers: {
                    Urgency: 'high',
                },
                notification: {
                    title: titleText,
                    body: bodyText,
                    icon: '/icons/icon-192x192.png',
                    badge: '/icons/icon-192x192.png',
                    vibrate: [100, 50, 100],
                    requireInteraction: false,
                },
                fcmOptions: {
                    link: 'https://thefinalburgerapp.web.app',
                },
            },
        };

        // Enviar notificación a cada usuario
        const sendPromises = usersSnapshot.docs.map(async (userDoc) => {
            const userData = userDoc.data();
            const fcmToken = userData.fcmToken;
            const userId = userDoc.id;

            try {
                await admin.messaging().send({
                    ...message,
                    token: fcmToken,
                });
                results.successful++;
                console.log(`✅ Notificación enviada a usuario ${userId}`);
            } catch (error) {
                results.failed++;
                console.error(`❌ Error enviando a usuario ${userId}: ${error.message}`);
            }
        });

        await Promise.all(sendPromises);

        console.log('');
        console.log('✅ Notificación broadcast completada');
        console.log(`📊 Resultados: ${results.successful} exitosas, ${results.failed} fallidas`);

        process.exit(0);
    } catch (error) {
        console.error('❌ Error enviando notificación broadcast:', error);
        process.exit(1);
    }
}

sendBroadcastNotification();

