import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HabitEvalTypeScreen extends StatelessWidget {
  const HabitEvalTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);
    const accent = Color(0xFFC63C54);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              '¿Cómo quieres evaluar tu\nprogreso?',
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _PrimaryChoice(
                    title: 'CON UN SÍ O NO',
                    subtitle:
                        'Registra si cumples la actividad o no',
                    onTap: () => context.push('/habit/new/define'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _PrimaryChoice extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PrimaryChoice({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB61F47),
                  Color(0xFFD12C63),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const Divider(color: Color(0xFF1F1F1F), height: 1),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Text(
              'ATRÁS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: const [
              _Dot(active: false),
              _Dot(active: true),
              _Dot(active: false),
              _Dot(active: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accent : Colors.transparent,
        border: Border.all(color: accent, width: 1),
      ),
    );
  }
}
