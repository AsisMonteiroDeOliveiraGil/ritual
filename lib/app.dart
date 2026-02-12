import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/features/habits/presentation/providers/auth_providers.dart';
import 'package:ritual/router/app_router.dart';

class RitualApp extends ConsumerWidget {
  const RitualApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(ensureSignedInProvider);

    return auth.when(
      data: (_) => MaterialApp.router(
        title: 'Ritual',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C7ED6)),
          useMaterial3: true,
        ),
        routerConfig: buildAppRouter(),
      ),
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error de autenticación: $err')),
        ),
      ),
    );
  }
}
