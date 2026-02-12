import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GymScreen extends StatelessWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gimnasio')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push('/settings'),
          child: const Text('Configuración'),
        ),
      ),
    );
  }
}
