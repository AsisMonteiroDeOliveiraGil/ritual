#!/usr/bin/env node
/*
 * Sends a release notification to all devices that have registered an FCM token.
 */
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function resolveServiceAccountPath() {
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return process.env.GOOGLE_APPLICATION_CREDENTIALS;
  }
  const defaultPath = path.resolve(__dirname, '..', 'firebase-service-account.json');
  if (fs.existsSync(defaultPath)) {
    return defaultPath;
  }
  throw new Error('No se encontró el archivo firebase-service-account.json');
}

function loadServiceAccount() {
  const serviceAccountPath = resolveServiceAccountPath();
  const json = fs.readFileSync(serviceAccountPath, 'utf8');
  return JSON.parse(json);
}

function extractTokensFromData(data, tokens) {
  if (!data || typeof data !== 'object') {
    return;
  }

  const stack = [{ value: data, keyPath: [] }];
  while (stack.length > 0) {
    const { value, keyPath } = stack.pop();

    if (value && typeof value === 'object') {
      if (Array.isArray(value)) {
        value.forEach((item, index) => {
          stack.push({ value: item, keyPath: keyPath.concat(index.toString()) });
        });
      } else {
        for (const [key, nestedValue] of Object.entries(value)) {
          stack.push({ value: nestedValue, keyPath: keyPath.concat(key) });
        }
      }
      continue;
    }

    if (typeof value === 'string') {
      const keyMatchesToken = keyPath.some((segment) =>
        typeof segment === 'string' && segment.toLowerCase().includes('token'),
      );
      if (keyMatchesToken && value.trim().length > 0) {
        tokens.add(value.trim());
      }
    }
  }
}

async function fetchAllTokens(db) {
  const tokens = new Set();

  // 1. Tokens guardados en la colección principal de usuarios
  const usersSnapshot = await db.collection('users').get();
  usersSnapshot.forEach((doc) => {
    const data = doc.data();
    if (!data) return;
    if (typeof data.fcmToken === 'string' && data.fcmToken.trim()) {
      tokens.add(data.fcmToken.trim());
    }
    extractTokensFromData(data, tokens);
  });

  // 2. Buscar colecciones adicionales relacionadas con tokens/notifications
  const candidateNames = new Set([
    'notification_tokens',
    'notifications_tokens',
    'device_tokens',
    'devices_tokens',
    'web_push_tokens',
    'webpush_tokens',
    'push_tokens',
    'push_subscriptions',
    'webPushSubscriptions',
    'anonymous_push_tokens',
  ]);

  const collections = await db.listCollections();
  const tokenCollections = collections.filter((collection) => {
    const name = collection.id;
    if (candidateNames.has(name)) return true;
    const lowered = name.toLowerCase();
    return (
      lowered.includes('token') &&
      (lowered.includes('push') || lowered.includes('notification') || lowered.includes('fcm'))
    );
  });

  for (const collection of tokenCollections) {
    const snapshot = await collection.get();
    snapshot.forEach((doc) => {
      extractTokensFromData(doc.data(), tokens);
    });
  }

  return Array.from(tokens);
}

async function sendReleaseNotification(version) {
  if (!version) {
    throw new Error('No se proporcionó versión de la app');
  }

  const serviceAccount = loadServiceAccount();
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  const db = admin.firestore();
  const messaging = admin.messaging();

  const tokens = await fetchAllTokens(db);
  if (tokens.length === 0) {
    console.log('⚠️  No se encontraron tokens FCM para enviar la notificación.');
    return;
  }

  const titleText = '🍭 CODEX WEB 🍬';
  const bodyText = `🔥🚀 Nueva version v${version} 🚀🔥`;
  const dataPayload = {
    type: 'codex_web_release',
    version,
  };

  const chunkSize = 500;
  let successCount = 0;
  let failureCount = 0;

  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    const response = await messaging.sendEachForMulticast({
      tokens: chunk,
      notification: {
        title: titleText,
        body: bodyText,
      },
      data: dataPayload,
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
    });

    successCount += response.successCount;
    failureCount += response.failureCount;

    if (response.responses) {
      response.responses.forEach((res, index) => {
        if (!res.success) {
          console.warn(
            `⚠️  Error enviando a token ${chunk[index]}:`,
            res.error && res.error.message ? res.error.message : res.error,
          );
        }
      });
    }
  }

  console.log(`✅ Notificaciones enviadas. Éxitos: ${successCount}, errores: ${failureCount}`);
}

(async () => {
  try {
    const version = process.argv[2] || process.env.TFB_APP_VERSION;
    await sendReleaseNotification(version);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error enviando la notificación de lanzamiento:', error);
    process.exit(1);
  }
})();
