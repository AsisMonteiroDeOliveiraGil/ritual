import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ritual/firebase_options.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _fcmInitialized = false;
bool _localInitialized = false;
bool _tzInitialized = false;
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
const int _cookingReminderNotificationId = 1300;
const int _footballReminderNotificationId = 2041;

Future<void> registerPushNotifications() async {
  if (_fcmInitialized || kIsWeb) return;
  _fcmInitialized = true;

  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) return;

  await FirebaseMessaging.instance.requestPermission();
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        debugPrint('APNS token not available yet; skipping FCM token sync.');
      } else {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _saveToken(user.uid, token);
        }
      }
    } else {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(user.uid, token);
      }
    }
  } on FirebaseException catch (error) {
    debugPrint('FCM token error: ${error.code}');
  } catch (error) {
    debugPrint('FCM token error: $error');
  }

  await _ensureLocalNotifications();
  try {
    await _scheduleDailyCookingReminder();
    await _scheduleDailyFootballReminder();
  } catch (error) {
    debugPrint('Daily reminder schedule error: $error');
  }

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
  const darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
    macOS: darwinSettings,
  );
  await _localNotifications.initialize(initSettings);

  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ;
  await androidPlugin?.createNotificationChannel(_habitChannel);
  await androidPlugin?.createNotificationChannel(_ringChannel);
  await _requestExactAlarmPermissionIfNeeded(androidPlugin);
}

Future<void> _requestExactAlarmPermissionIfNeeded(
  AndroidFlutterLocalNotificationsPlugin? androidPlugin,
) async {
  if (kIsWeb || androidPlugin == null) return;
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final canScheduleExact =
        await androidPlugin.canScheduleExactNotifications() ?? false;
    if (!canScheduleExact) {
      await androidPlugin.requestExactAlarmsPermission();
    }
  } catch (error) {
    debugPrint('Exact alarm permission request error: $error');
  }
}

Future<void> _ensureTimezone() async {
  if (_tzInitialized || kIsWeb) return;
  tz_data.initializeTimeZones();
  try {
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
  _tzInitialized = true;
}

Future<void> _scheduleDailyCookingReminder() async {
  if (kIsWeb) return;
  await _ensureTimezone();

  final now = tz.TZDateTime.now(tz.local);
  var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 13);
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }

  await _scheduleDailyReminder(
    id: _cookingReminderNotificationId,
    title: 'Recordatorio',
    body: 'Tienes que cocinar a las 13:00',
    when: next,
    androidDetails: const AndroidNotificationDetails(
      'daily_cooking_reminder_v1',
      'Recordatorio cocina',
      channelDescription: 'Recordatorio diario para cocinar a las 13:00',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    ),
  );
}

Future<void> _scheduleDailyFootballReminder() async {
  if (kIsWeb) return;
  await _ensureTimezone();

  final now = tz.TZDateTime.now(tz.local);
  var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 41);
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }

  await _scheduleDailyReminder(
    id: _footballReminderNotificationId,
    title: 'Recordatorio',
    body: 'Tiene que jugar al futbol',
    when: next,
    androidDetails: const AndroidNotificationDetails(
      'daily_football_reminder_v1',
      'Recordatorio futbol',
      channelDescription: 'Recordatorio diario para jugar al futbol a las 20:41',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    ),
  );
}

Future<void> _scheduleDailyReminder({
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime when,
  required AndroidNotificationDetails androidDetails,
}) async {
  final details = NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
    macOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  try {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } on PlatformException catch (error) {
    if (error.code == 'exact_alarms_not_permitted') {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }
    rethrow;
  }
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
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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
