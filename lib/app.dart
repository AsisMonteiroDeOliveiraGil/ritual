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
        debugShowCheckedModeBanner: false,
        title: 'Ritual',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0B0D11),
          canvasColor: const Color(0xFF0B0D11),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC63C54),
            brightness: Brightness.dark,
          ),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFFC63C54),
            circularTrackColor: Color(0xFF1E2128),
          ),
          useMaterial3: true,
        ),
        routerConfig: buildAppRouter(),
      ),
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0B0D11),
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF111111),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    err.toString().contains('no está autorizado')
                        ? Icons.lock_outline
                        : Icons.cloud_off_outlined,
                    size: 62,
                    color: const Color(0xFFC63C54),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No se pudo iniciar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    err.toString().contains('no está autorizado')
                        ? 'Este dispositivo no está autorizado para esta cuenta.'
                        : 'Ha ocurrido un error de autenticación. Inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(ensureSignedInProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
