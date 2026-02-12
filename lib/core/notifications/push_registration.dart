import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ritual/firebase_options.dart';

bool _fcmInitialized = false;
bool _localInitialized = false;
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel _habitChannel = AndroidNotificationChannel(
  'habit_completions_v2',
  'Habitos completados',
  description: 'Notificaciones cuando completas un habito',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('chachin'),
);

const AndroidNotificationChannel _ringChannel = AndroidNotificationChannel(
  'find_phone_v1',
  'Encontrar movil',
  description: 'Notificaciones para encontrar tu movil',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('chachin'),
  audioAttributesUsage: AudioAttributesUsage.alarm,
);

Future<void> registerPushNotifications() async {
  if (_fcmInitialized || kIsWeb) return;
  _fcmInitialized = true;

  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) return;

  await FirebaseMessaging.instance.requestPermission();
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await _saveToken(user.uid, token);
  }

  await _ensureLocalNotifications();

  FirebaseMessaging.onMessage.listen((message) async {
    await _showLocalNotification(message);
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await _saveToken(user.uid, newToken);
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await _ensureLocalNotifications();
  await _showLocalNotification(message);
}

Future<void> _ensureLocalNotifications() async {
  if (_localInitialized) return;
  _localInitialized = true;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _localNotifications.initialize(initSettings);

  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ;
  await androidPlugin?.createNotificationChannel(_habitChannel);
  await androidPlugin?.createNotificationChannel(_ringChannel);
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  final type = message.data['type']?.toString();
  final isRing = type == 'ring_phone';
  final channel = isRing ? _ringChannel : _habitChannel;
  final title = notification?.title ??
      (isRing ? '¿Dónde está mi móvil?' : 'Hábito completado');
  final body = notification?.body ??
      (isRing ? 'Hazlo sonar' : 'Has completado un hábito');

  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('chachin'),
        playSound: true,
        audioAttributesUsage: isRing
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
      ),
    ),
  );
}

Future<void> _saveToken(String uid, String token) async {
  final ref = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('fcm_tokens')
      .doc(token);

  await ref.set(
    {
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}
