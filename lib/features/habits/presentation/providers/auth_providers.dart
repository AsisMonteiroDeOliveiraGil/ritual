import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:ritual/core/notifications/push_registration.dart';
import 'package:ritual/core/security/device_access.dart';

const _fixedUid = '9fAbFEzg0KTBCs5jfTlNOsvEH5u2';
const _customTokenUrl =
    'https://issuecustomtoken-j6vn7raqgq-uc.a.run.app';
const _customAuthToken = 'iOaNUSI8A5CQg1w-KjW0Uezu8p947TEY';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final ensureSignedInProvider = FutureProvider<User>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  var user = auth.currentUser;
  if (user == null || user.uid != _fixedUid) {
    if (user != null && user.uid != _fixedUid) {
      await auth.signOut();
    }
    final token = await _fetchCustomToken();
    final credential = await auth.signInWithCustomToken(token);
    user = credential.user;
  }
  if (user == null) {
    throw StateError('Custom token sign-in failed');
  }
  await ensureCurrentDeviceAuthorized(user.uid);
  await registerPushNotifications();
  return user;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

Future<String> _fetchCustomToken() async {
  final response = await http.post(
    Uri.parse(_customTokenUrl),
    headers: {
      'Authorization': 'Bearer $_customAuthToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'uid': _fixedUid}),
  );
  if (response.statusCode != 200) {
    throw StateError('Custom token request failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final token = data['token'] as String?;
  if (token == null || token.isEmpty) {
    throw StateError('Custom token missing');
  }
  return token;
}
