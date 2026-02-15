import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/providers/new_habit_draft_provider.dart';

class HabitFrequencyScreen extends ConsumerStatefulWidget {
  const HabitFrequencyScreen({super.key});

  @override
  ConsumerState<HabitFrequencyScreen> createState() =>
      _HabitFrequencyScreenState();
}

class _HabitFrequencyScreenState
    extends ConsumerState<HabitFrequencyScreen> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(newHabitDraftProvider);
    _selected = _options.indexOf(draft.frequencyLabel);
    if (_selected < 0) {
      _selected = 0;
    }
  }

  List<String> get _options => const [
        'Cada día',
        'Días específicos de la semana',
        'Días específicos del mes',
        'Días específicos del año',
        'Algunos días por periodo',
        'Repetir',
      ];

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);
    const accent = Color(0xFFC63C54);

    final options = _options;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Text(
              '¿Con qué frecuencia quieres hacerlo?',
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final selected = _selected == index;
                  return _RadioRow(
                    label: options[index],
                    selected: selected,
                    onTap: () {
                      setState(() => _selected = index);
                      ref
                          .read(newHabitDraftProvider.notifier)
                          .setFrequencyLabel(options[index]);
                    },
                  );
                },
              ),
            ),
            _BottomBar(
              onNext: () {
                ref
                    .read(newHabitDraftProvider.notifier)
                    .setFrequencyLabel(options[_selected]);
                context.push('/habit/new/schedule');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? accent : Colors.white24,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onNext;

  const _BottomBar({required this.onNext});

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
              _Dot(active: false),
              _Dot(active: true),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onNext,
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
