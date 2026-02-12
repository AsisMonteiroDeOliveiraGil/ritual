// Limpia usuarios y colecciones relacionadas en Firebase Auth y Firestore.

console.clear();

const http = require('http');
const https = require('https');
const { execSync } = require('child_process');
const { HttpsProxyAgent } = require('https-proxy-agent');
const { HttpProxyAgent } = require('http-proxy-agent');
const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

function printMessage(message) {
  try {
    const escaped = message
      .replace(/\\/g, '\\\\')
      .replace(/"/g, '\\"')
      .replace(/\$/g, '\\$')
      .replace(/`/g, '\\`')
      .replace(/\n/g, '\\n');
    execSync(`printf "${escaped}\\n" | lolcat`, {
      stdio: 'inherit',
      shell: '/bin/bash',
    });
  } catch (error) {
    console.log(message);
  }
}

function showArt(message) {
  try {
    const escaped = message
      .replace(/\\/g, '\\\\')
      .replace(/"/g, '\\"')
      .replace(/\$/g, '\\$')
      .replace(/`/g, '\\`');
    const art = execSync(`figlet -f big -w 200 "${escaped}"`, {
      encoding: 'utf-8',
      shell: '/bin/bash',
    });
    const width = Math.max(...art.split('\n').map((line) => line.length));
    const separator = '='.repeat(width);
    printMessage(separator);
    printMessage(art.trim());
    printMessage(separator);
  } catch (error) {
    console.log('\n' + '='.repeat(60));
    console.log(message);
    console.log('='.repeat(60) + '\n');
  }
}

const proxyUrl =
  process.env.HTTPS_PROXY ||
  process.env.HTTP_PROXY ||
  process.env.https_proxy ||
  process.env.http_proxy ||
  '';

if (proxyUrl) {
  const httpsAgent = new HttpsProxyAgent(proxyUrl);
  const httpAgent = new HttpProxyAgent(proxyUrl);
  https.globalAgent = httpsAgent;
  http.globalAgent = httpAgent;
  printMessage(`🌐 Usando proxy para las peticiones salientes: ${proxyUrl}`);
} else {
  printMessage('🌐 Ejecutando sin proxy HTTP(S)');
}

function initializeFirebase() {
  if (admin.apps.length) return;

  const serviceAccountPath = path.resolve(
    process.cwd(),
    'firebase-service-account.json',
  );

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: 'https://the-final-burger-default-rtdb.firebaseio.com',
    });
    return;
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    databaseURL: 'https://the-final-burger-default-rtdb.firebaseio.com',
  });
}

initializeFirebase();

const auth = admin.auth();
const db = admin.firestore();

const PROTECTED_COLLECTIONS = new Set([
  'competitions',
  'events',
  'restaurants',
  'restaurant_profiles',
  'restaurant_promotions',
  'restaurant_metrics',
  'menus',
  'items',
  'stands',
  'menu_digitization_events',
  'purchases',
]);

const COLLECTIONS_TO_CLEAN = [
  'activityNotifications',
  'archivedChats',
  'badges',
  'blockedGroups',
  'blockedUsers',
  'burgerLists',
  'burgers',
  'chatInvites',
  'chatParticipants',
  'chatReports',
  'chats',
  'comments',
  'competitionEnrollmentRequests',
  'contentReports',
  'deletedMessages',
  'experienceReports',
  'experiences',
  'favoriteBurgers',
  'favorites',
  'followRequests',
  'followers',
  'following',
  'follows',
  'gamification',
  'groupReports',
  'juryFeedback',
  'likes',
  'messages',
  'moderationIssues',
  'notifications',
  'posts',
  'ratings',
  'realtime_notifications',
  'recommendations',
  'reviews',
  'shares',
  'users',
  'votes',
];

const POST_CLEAN_CHECKS = ['users', 'posts', 'experiences', 'reviews', 'chats'];

async function deleteDocumentRecursive(docRef, depth = 0) {
  let deleted = 0;
  const indent = '  '.repeat(depth);
  const subcollections = await docRef.listCollections();

  for (const subcollection of subcollections) {
    const subDeleted = await deleteCollectionRecursive(
      subcollection,
      depth + 1,
    );
    deleted += subDeleted;
    if (subDeleted > 0) {
      printMessage(
        `${indent}↳ Subcolección ${subcollection.path} (${subDeleted}) eliminada`,
      );
    }
  }

  await docRef.delete();
  return deleted + 1;
}

async function deleteCollectionRecursive(collectionRef, depth = 0) {
  let deleted = 0;
  while (true) {
    const snapshot = await collectionRef.limit(250).get();
    if (snapshot.empty) break;
    for (const doc of snapshot.docs) {
      deleted += await deleteDocumentRecursive(doc.ref, depth);
    }
  }
  return deleted;
}

async function deleteNamedCollection(collectionName) {
  try {
    const collectionRef = db.collection(collectionName);
    const deletedCount = await deleteCollectionRecursive(collectionRef);
    if (deletedCount === 0) {
      printMessage(`✅ Colección ${collectionName} ya estaba vacía`);
    } else {
      printMessage(
        `✅ Colección ${collectionName} limpiada (${deletedCount} documentos)`,
      );
    }
    return deletedCount;
  } catch (error) {
    printMessage(
      `❌ Error eliminando colección ${collectionName}: ${error.message}`,
    );
    return 0;
  }
}

async function deleteAllFirestoreData() {
  printMessage('\n🔥 Iniciando limpieza COMPLETA de Firestore...');
  let totalDeletedDocs = 0;
  for (const collectionName of COLLECTIONS_TO_CLEAN) {
    if (PROTECTED_COLLECTIONS.has(collectionName)) {
      printMessage(
        `🛡️ Colección protegida detectada (${collectionName}), se omite de la limpieza`,
      );
      continue;
    }
    totalDeletedDocs += await deleteNamedCollection(collectionName);
  }
  return totalDeletedDocs;
}

async function verifyCriticalCollections() {
  printMessage('\n🔍 Verificando limpiezas críticas...');
  for (const collectionName of POST_CLEAN_CHECKS) {
    try {
      const snapshot = await db.collection(collectionName).limit(1).get();
      if (snapshot.empty) {
        printMessage(`✅ ${collectionName}: Vacía`);
      } else {
        printMessage(`❌ ${collectionName}: aún contiene datos`);
      }
    } catch (error) {
      printMessage(
        `⚠️ No se pudo verificar ${collectionName}: ${error.message}`,
      );
    }
  }
}

async function deleteAllAuthUsers() {
  printMessage('🧹 Iniciando limpieza COMPLETA de todos los usuarios...');

  let deletedAuthCount = 0;
  let authErrorCount = 0;
  let nextPageToken;

  do {
    const listUsersResult = await auth.listUsers(1000, nextPageToken);
    const users = listUsersResult.users;
    if (users.length === 0 && !nextPageToken) {
      printMessage('✅ No hay usuarios en Firebase Auth');
      break;
    }

    for (const user of users) {
      try {
        printMessage(`\n🗑️ Eliminando usuario de Auth: ${user.email || user.uid}`);
        await auth.deleteUser(user.uid);
        deletedAuthCount++;
        printMessage('   ✅ Usuario eliminado de Auth');
      } catch (error) {
        printMessage(`   ❌ Error eliminando de Auth: ${error.message}`);
        authErrorCount++;
      }
    }

    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  printMessage(
    `\n📊 Resumen Auth: ${deletedAuthCount} eliminados, ${authErrorCount} errores`,
  );

  return { deletedAuthCount, authErrorCount };
}

async function cleanAllUsers() {
  try {
    const { deletedAuthCount, authErrorCount } = await deleteAllAuthUsers();
    const deletedDocsCount = await deleteAllFirestoreData();
    await verifyCriticalCollections();

    if (deletedAuthCount > 0 || deletedDocsCount > 0) {
      showArt(`Done(${deletedAuthCount}/${deletedDocsCount})`);
    } else if (authErrorCount === 0) {
      printMessage('✅ No había datos que limpiar');
    }
  } catch (error) {
    printMessage(`❌ Error durante la limpieza: ${error.message}`);
  } finally {
    process.exit(0);
  }
}

cleanAllUsers();

