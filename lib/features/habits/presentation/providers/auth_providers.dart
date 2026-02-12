import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/core/notifications/push_registration.dart';

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
  await registerPushNotifications();
  return user;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

Future<String> _fetchCustomToken() async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(_customTokenUrl));
    request.headers.set('Authorization', 'Bearer $_customAuthToken');
    request.headers.set('Content-Type', 'application/json');
    request.add(
      utf8.encode(jsonEncode({'uid': _fixedUid})),
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw StateError('Custom token request failed: ${response.statusCode}');
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Custom token missing');
    }
    return token;
  } finally {
    client.close();
  }
}
