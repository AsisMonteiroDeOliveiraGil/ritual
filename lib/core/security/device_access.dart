import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _deviceIdKey = 'ritual_device_id_v1';

Future<String> getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_deviceIdKey);
  if (existing != null && existing.isNotEmpty) return existing;

  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  final generated = base64UrlEncode(bytes).replaceAll('=', '');
  await prefs.setString(_deviceIdKey, generated);
  return generated;
}

Future<void> ensureCurrentDeviceAuthorized(String uid) async {
  final deviceId = await getOrCreateDeviceId();
  final devices = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('allowed_devices');
  final pendingDevices = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('pending_devices');

  final deviceRef = devices.doc(deviceId);
  final deviceDoc = await deviceRef.get();
  if (deviceDoc.exists) {
    await deviceRef.set(
      {
        'lastSeenAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return;
  }

  // En desarrollo permitimos acceso automático (incluye emuladores/simuladores).
  if (kDebugMode) {
    await deviceRef.set(
      {
        'deviceId': deviceId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isCurrent': true,
        'debugAutoAuthorized': true,
      },
      SetOptions(merge: true),
    );
    return;
  }

  final anyAuthorized = await devices.limit(1).get();
  if (anyAuthorized.docs.isEmpty) {
    await deviceRef.set({
      'deviceId': deviceId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
      'isCurrent': true,
    });
    return;
  }

  await pendingDevices.doc(deviceId).set(
    {
      'deviceId': deviceId,
      'requestedAt': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.name,
      'status': 'pending',
    },
    SetOptions(merge: true),
  );

  throw StateError(
    'Este dispositivo no está autorizado (ID: $deviceId).',
  );
}
