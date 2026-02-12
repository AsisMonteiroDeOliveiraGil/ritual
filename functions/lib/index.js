"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ringPhone = exports.seedHabits = exports.markCompletion = exports.issueCustomToken = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
const luxon_1 = require("luxon");
admin.initializeApp();
const sharedSecret = (0, params_1.defineSecret)('HA_SHARED_SECRET');
const fixedUid = '9fAbFEzg0KTBCs5jfTlNOsvEH5u2';
exports.issueCustomToken = (0, https_1.onRequest)({ secrets: [sharedSecret] }, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const secretValue = sharedSecret.value();
    if (!secretValue) {
        res.status(500).json({ error: 'Missing shared secret config' });
        return;
    }
    const authHeader = req.headers.authorization ?? '';
    const token = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length)
        : '';
    if (!token || token !== secretValue) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    const { uid } = req.body ?? {};
    if (!uid || uid !== fixedUid) {
        res.status(400).json({ error: 'Invalid uid' });
        return;
    }
    const customToken = await admin.auth().createCustomToken(uid);
    res.status(200).json({ token: customToken });
});
exports.markCompletion = (0, https_1.onRequest)({ secrets: [sharedSecret] }, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const secretValue = sharedSecret.value();
    if (!secretValue) {
        res.status(500).json({ error: 'Missing shared secret config' });
        return;
    }
    const authHeader = req.headers.authorization ?? '';
    const token = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length)
        : '';
    if (!token || token !== secretValue) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    const { uid, habitHaId, dateKey, timestamp, source } = req.body ?? {};
    if (!uid || !habitHaId) {
        res
            .status(400)
            .json({ error: 'uid and habitHaId are required' });
        return;
    }
    const db = admin.firestore();
    const haSnap = await db
        .collection('users')
        .doc(uid)
        .collection('habits')
        .where('haId', '==', habitHaId)
        .limit(1)
        .get();
    if (haSnap.empty) {
        res.status(404).json({ error: 'Habit not found' });
        return;
    }
    if (haSnap.size > 1) {
        res.status(409).json({ error: 'Multiple habits found for haId' });
        return;
    }
    const habitDoc = haSnap.docs[0];
    if (habitDoc.get('active') !== true) {
        res.status(404).json({ error: 'Habit not found or inactive' });
        return;
    }
    const resolvedHabitId = habitDoc.id;
    const habitName = habitDoc.get('name') ?? habitHaId;
    const nowMs = typeof timestamp === 'number' ? timestamp : Date.now();
    if (dateKey != null && typeof dateKey === 'string') {
        const validFormat = /^\d{4}-\d{2}-\d{2}$/.test(dateKey);
        if (!validFormat) {
            res.status(400).json({ error: 'Invalid dateKey format' });
            return;
        }
    }
    const serverDateKey = dateKey && typeof dateKey === 'string'
        ? dateKey
        : luxon_1.DateTime.fromMillis(nowMs).setZone('Europe/Madrid').toFormat('yyyy-MM-dd');
    const completionId = `${resolvedHabitId}_${serverDateKey}`;
    const completionRef = db
        .collection('users')
        .doc(uid)
        .collection('completions')
        .doc(completionId);
    let created = false;
    let alreadyCompleted = false;
    await db.runTransaction(async (tx) => {
        const existing = await tx.get(completionRef);
        if (existing.exists) {
            alreadyCompleted = true;
            return;
        }
        created = true;
        tx.set(completionRef, {
            habitId: resolvedHabitId,
            habitHaId,
            dateKey: serverDateKey,
            source: source ?? 'ha',
            timestamp: nowMs,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    if (created) {
        const tokensSnap = await db
            .collection('users')
            .doc(uid)
            .collection('fcm_tokens')
            .get();
        const tokens = tokensSnap.docs
            .map((doc) => doc.get('token') ?? doc.id)
            .filter((t) => t && t.length > 0);
        if (tokens.length > 0) {
            await admin.messaging().sendEachForMulticast({
                tokens,
                notification: {
                    title: 'Hábito completado',
                    body: habitName,
                },
                data: {
                    habitHaId,
                    dateKey: serverDateKey,
                    source: String(source ?? 'ha'),
                },
            });
        }
    }
    res.status(200).json({
        created,
        alreadyCompleted: alreadyCompleted || created === false,
        completionId,
        habitId: resolvedHabitId,
        dateKey: serverDateKey,
    });
});
exports.seedHabits = (0, https_1.onRequest)({ secrets: [sharedSecret] }, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const secretValue = sharedSecret.value();
    if (!secretValue) {
        res.status(500).json({ error: 'Missing shared secret config' });
        return;
    }
    const authHeader = req.headers.authorization ?? '';
    const token = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length)
        : '';
    if (!token || token !== secretValue) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    const { uid } = req.body ?? {};
    if (!uid || uid !== fixedUid) {
        res.status(400).json({ error: 'Invalid uid' });
        return;
    }
    const habits = [
        {
            name: 'Agua al despertar 💧',
            haId: 'agua_al_despertar',
            icon: 'water',
            color: 0xFF1C7ED6,
        },
        {
            name: 'Cepillarme los dientes antes de desayunar 🪥',
            haId: 'dientes_desayunar',
            icon: 'check',
            color: 0xFF37B24D,
        },
        {
            name: 'Skin karen por la mañana 🧴☀️',
            haId: 'skin_karen_manana',
            icon: 'sun',
            color: 0xFFF59F00,
        },
        {
            name: 'Desayunar lo primero (no recoger nada antes)',
            haId: 'desayunar_primero',
            icon: 'check',
            color: 0xFFE03131,
        },
        {
            name: 'Suplementos mañana 💊',
            haId: 'suplementos_manana',
            icon: 'pill',
            color: 0xFF9C36B5,
        },
        {
            name: 'Skin karen noche 🧴🌚',
            haId: 'skin_karen_noche',
            icon: 'moon',
            color: 0xFF37B24D,
        },
        {
            name: 'Suplementos noche 💊',
            haId: 'suplementos_noche',
            icon: 'pill',
            color: 0xFFF59F00,
        },
        {
            name: 'Cepillarme los dientes antes de dormir 🪥🌚',
            haId: 'dientes_dormir',
            icon: 'check',
            color: 0xFF37B24D,
        },
        {
            name: '2 Litros de agua al día 💦',
            haId: 'agua_2l_dia',
            icon: 'water',
            color: 0xFF1C7ED6,
        },
        {
            name: 'Meditar antes de dormir 🧘‍♀️',
            haId: 'meditar_dormir',
            icon: 'skin',
            color: 0xFF9C36B5,
        },
    ];
    const normalizeName = (value) => value
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .trim()
        .toLowerCase()
        .replace(/\s+/g, ' ');
    const db = admin.firestore();
    const habitsRef = db.collection('users').doc(uid).collection('habits');
    const existingSnap = await habitsRef.get();
    const existingByHaId = new Map();
    for (const doc of existingSnap.docs) {
        const haId = doc.get('haId');
        if (typeof haId === 'string' && haId.length > 0) {
            existingByHaId.set(haId, doc.id);
        }
    }
    const batch = db.batch();
    habits.forEach((habit, index) => {
        const docId = existingByHaId.get(habit.haId) ?? habitsRef.doc().id;
        const docRef = habitsRef.doc(docId);
        batch.set(docRef, {
            name: habit.name,
            nameLower: normalizeName(habit.name),
            haId: habit.haId,
            icon: habit.icon,
            color: habit.color,
            active: true,
            order: index + 1,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
    await batch.commit();
    res.status(200).json({ count: habits.length });
});
exports.ringPhone = (0, https_1.onRequest)({ secrets: [sharedSecret] }, async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const secretValue = sharedSecret.value();
    if (!secretValue) {
        res.status(500).json({ error: 'Missing shared secret config' });
        return;
    }
    const authHeader = req.headers.authorization ?? '';
    const token = authHeader.startsWith('Bearer ')
        ? authHeader.slice('Bearer '.length)
        : '';
    if (!token || token !== secretValue) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
    }
    const { uid } = req.body ?? {};
    if (!uid || uid !== fixedUid) {
        res.status(400).json({ error: 'Invalid uid' });
        return;
    }
    const db = admin.firestore();
    const tokensSnap = await db
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .get();
    const tokens = tokensSnap.docs
        .map((doc) => doc.get('token') ?? doc.id)
        .filter((t) => t && t.length > 0);
    if (tokens.length === 0) {
        res.status(404).json({ error: 'No tokens registered' });
        return;
    }
    const result = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
            title: '¿Dónde está mi móvil?',
            body: 'Hazlo sonar',
        },
        data: {
            type: 'ring_phone',
        },
        android: {
            priority: 'high',
            notification: {
                channelId: 'find_phone_v1',
                sound: 'chachin',
            },
        },
    });
    res.status(200).json({ sent: result.successCount });
});
