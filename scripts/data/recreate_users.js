// Crea usuarios de prueba en Firebase Auth y Firestore (users/{uid}).
// Ejecutar desde la raíz del proyecto, DESPUÉS de scripts/data/delete.js.
// Contraseña por defecto: Test1234!

const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');

const PASSWORD = 'Test1234!';

const USERS = [
  { email: 'dev@thefinalburgerapp.test', displayName: 'Dev Test', role: 'Dev' },
  { email: 'customer1@thefinalburgerapp.test', displayName: 'Cliente Uno', role: 'customer' },
  { email: 'customer2@thefinalburgerapp.test', displayName: 'Cliente Dos', role: 'customer' },
  { email: 'customer3@thefinalburgerapp.test', displayName: 'Cliente Tres', role: 'customer' },
];

function initializeFirebase() {
  if (admin.apps.length) return;

  const atRoot = path.resolve(process.cwd(), 'firebase-service-account.json');
  const atFunctions = path.resolve(process.cwd(), 'functions', 'serviceAccountKey.json');

  const p = fs.existsSync(atRoot) ? atRoot : fs.existsSync(atFunctions) ? atFunctions : null;
  if (p) {
    admin.initializeApp({
      credential: admin.credential.cert(require(p)),
      storageBucket: 'thefinalburgerapp.firebasestorage.app',
    });
  } else {
    admin.initializeApp({ credential: admin.credential.applicationDefault() });
  }
}

initializeFirebase();

const auth = admin.auth();
const db = admin.firestore();

async function recreateUsers() {
  console.log('Creando usuarios de prueba en Auth y Firestore...\n');

  for (const u of USERS) {
    try {
      const created = await auth.createUser({
        email: u.email,
        password: PASSWORD,
        displayName: u.displayName,
        emailVerified: true,
      });

      await auth.setCustomUserClaims(created.uid, { role: u.role });

      await db.collection('users').doc(created.uid).set({
        email: u.email,
        displayName: u.displayName,
        role: u.role,
        photoURL: null,
        photoUrl: null,
        avatarUrl: null,
        followersCount: 0,
        followingCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log(`  ${u.role.padEnd(8)} ${u.email} (uid: ${created.uid})`);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        console.log(`  (omitido, ya existe) ${u.email}`);
      } else {
        console.error(`  Error ${u.email}:`, e.message);
      }
    }
  }

  console.log('\nContraseña de todos: ' + PASSWORD);
  console.log('Listo. Ejecuta el seed: cd functions && npx ts-node src/seed_all_user_data.ts');
}

recreateUsers().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
