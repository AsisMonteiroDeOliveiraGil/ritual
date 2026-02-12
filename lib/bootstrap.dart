import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ritual/app.dart';
import 'package:ritual/firebase_options.dart';
import 'package:ritual/core/notifications/push_registration.dart';

Future<void> bootstrap() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      runApp(const ProviderScope(child: RitualApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
    },
  );
}
