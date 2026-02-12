import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/providers/new_habit_draft_provider.dart';

class HabitDefineScreen extends ConsumerStatefulWidget {
  const HabitDefineScreen({super.key});

  @override
  ConsumerState<HabitDefineScreen> createState() => _HabitDefineScreenState();
}

class _HabitDefineScreenState extends ConsumerState<HabitDefineScreen> {
  late final TextEditingController _habitController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _haIdController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(newHabitDraftProvider);
    _habitController = TextEditingController(text: draft.name);
    _descriptionController = TextEditingController(text: draft.description);
    _haIdController = TextEditingController(text: draft.haId);
  }

  @override
  void dispose() {
    _habitController.dispose();
    _descriptionController.dispose();
    _haIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);
    const accent = Color(0xFFC63C54);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Text(
              'Define tu hábito',
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel(text: 'Hábito'),
                  const SizedBox(height: 8),
                  _OutlineInput(
                    controller: _habitController,
                    hint: '',
                    focused: true,
                    onChanged: (value) =>
                        ref.read(newHabitDraftProvider.notifier).setName(value),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'p. ej., Dormir temprano.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _OutlineInput(
                    controller: _descriptionController,
                    hint: 'Descripción (opcional)',
                    focused: false,
                    onChanged: (value) => ref
                        .read(newHabitDraftProvider.notifier)
                        .setDescription(value),
                  ),
                  const SizedBox(height: 18),
                  const _FieldLabel(text: 'Identificador HA'),
                  const SizedBox(height: 8),
                  _OutlineInput(
                    controller: _haIdController,
                    hint: 'p. ej., piel_karen',
                    focused: false,
                    onChanged: (value) =>
                        ref.read(newHabitDraftProvider.notifier).setHaId(value),
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _OutlineInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool focused;
  final ValueChanged<String>? onChanged;

  const _OutlineInput({
    required this.controller,
    required this.hint,
    required this.focused,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = focused ? const Color(0xFFC63C54) : Colors.white24;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFFC63C54),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ),
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
              _Dot(active: false),
              _Dot(active: true),
              _Dot(active: false),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/habit/new/frequency'),
            child: const Text(
              'SIGUIENTE',
              style: TextStyle(
                color: Color(0xFFC63C54),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
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
