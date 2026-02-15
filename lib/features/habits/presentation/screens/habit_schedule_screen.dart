import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';
import 'package:ritual/features/habits/presentation/providers/new_habit_draft_provider.dart';

class HabitScheduleScreen extends ConsumerStatefulWidget {
  const HabitScheduleScreen({super.key});

  @override
  ConsumerState<HabitScheduleScreen> createState() =>
      _HabitScheduleScreenState();
}

class _HabitScheduleScreenState extends ConsumerState<HabitScheduleScreen> {
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _endEnabled = false;
  int _reminderCount = 0;
  int _priority = 1;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(newHabitDraftProvider);
    _startDate = draft.startDate;
    _endDate = draft.endDate;
    _endEnabled = draft.endDate != null;
    _reminderCount = draft.reminderCount;
    _priority = draft.priority;
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final y = date.year % 100;
    return '$m/$d/$y';
  }

  int _daysBetween(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFC63C54),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endEnabled && _endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 1));
        }
        ref.read(newHabitDraftProvider.notifier).setStartDate(_startDate);
        ref.read(newHabitDraftProvider.notifier).setEndDate(_endDate);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final base = _endDate ?? _startDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFC63C54),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        ref.read(newHabitDraftProvider.notifier).setEndDate(_endDate);
      });
    }
  }

  Future<void> _pickTimeReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFC63C54),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderCount = (_reminderCount + 1).clamp(0, 99);
        ref
            .read(newHabitDraftProvider.notifier)
            .setReminderCount(_reminderCount);
      });
    }
  }

  Future<void> _showPrioritySheet() async {
    var temp = _priority;
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Establecer prioridad',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _SheetButton(
                      label: '−',
                      onTap: () => temp = (temp - 1).clamp(1, 9),
                      onChanged: () => (context as Element).markNeedsBuild(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$temp',
                          style: const TextStyle(
                            color: Color(0xFFC63C54),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _SheetButton(
                      label: '+',
                      onTap: () => temp = (temp + 1).clamp(1, 9),
                      onChanged: () => (context as Element).markNeedsBuild(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Pill(text: 'Predeterminado - $temp'),
              const SizedBox(height: 12),
              const Text(
                'Las actividades con mayor prioridad se mostrarán\nmás arriba en la lista',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SheetAction(
                      label: 'CERRAR',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetAction(
                      label: 'ACEPTAR',
                      accent: true,
                      onTap: () => Navigator.of(context).pop(temp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _priority = result;
        ref.read(newHabitDraftProvider.notifier).setPriority(_priority);
      });
    }
  }

  Future<void> _saveHabit() async {
    final draft = ref.read(newHabitDraftProvider);
    final create = await ref.read(createHabitProvider.future);
    final name = draft.name.trim().isEmpty ? 'Nuevo hábito' : draft.name.trim();
    await create(
      name: name,
      icon: draft.iconName,
      color: draft.color,
      description: draft.description,
      haId: draft.haId,
      categoryLabel: draft.categoryLabel.isEmpty ? null : draft.categoryLabel,
      categoryColor: draft.categoryColor,
      categoryIconCodePoint: draft.categoryIconCodePoint,
      frequencyLabel: draft.frequencyLabel,
      priority: draft.priority,
      startDate: _startDate,
      endDate: _endEnabled ? _endDate : null,
      reminderCount: _reminderCount,
    );
    ref.read(newHabitDraftProvider.notifier).reset();
    if (mounted) {
      context.go('/today');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF111111);
    const accent = Color(0xFFC63C54);

    final startLabel =
        _isSameDay(_startDate, DateTime.now()) ? 'Hoy' : _formatDate(_startDate);
    final endLabel = _endDate == null ? 'Definir' : _formatDate(_endDate!);
    final duration =
        _endDate == null ? null : _daysBetween(_startDate, _endDate!);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const Text(
              '¿Cuándo quieres hacerlo?',
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _RowTile(
                    icon: Icons.calendar_today,
                    label: 'Fecha de inicio',
                    trailing: _Pill(text: startLabel),
                    onTap: _pickStartDate,
                  ),
                  const _Divider(),
                  _RowTile(
                    icon: Icons.calendar_today,
                    label: 'Fecha de fin',
                    trailing: _Toggle(
                      value: _endEnabled,
                      onChanged: (value) {
                        setState(() {
                          _endEnabled = value;
                          if (!_endEnabled) {
                            _endDate = null;
                          } else {
                            _endDate =
                                _startDate.add(const Duration(days: 1));
                          }
                          ref
                              .read(newHabitDraftProvider.notifier)
                              .setEndDate(_endDate);
                        });
                      },
                    ),
                  ),
                  if (_endEnabled) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 34),
                        _Pill(text: endLabel),
                        const SizedBox(width: 14),
                        if (duration != null)
                          Text(
                            '$duration',
                            style: const TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (duration != null)
                          const Text(
                            ' días.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _pickEndDate,
                          child: const Text(
                            'Cambiar',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const _Divider(),
                  _RowTile(
                    icon: Icons.notifications_none,
                    label: 'Hora y recordatorios',
                    trailing: _Badge(text: '$_reminderCount'),
                    onTap: _pickTimeReminder,
                  ),
                  const _Divider(),
                  _RowTile(
                    icon: Icons.flag,
                    label: 'Prioridad',
                    trailing: _Pill(text: _priority.toString()),
                    onTap: _showPrioritySheet,
                  ),
                ],
              ),
            ),
            _BottomBar(onSave: _saveHabit),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _RowTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1218),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2A1218),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
      width: 52,
      height: 30,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF3A1720) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFFE54B6A),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onSave;

  const _BottomBar({required this.onSave});

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
            onTap: onSave,
            child: const Text(
              'GUARDAR',
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

class _SheetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onChanged;

  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        onChanged();
      },
      child: SizedBox(
        width: 56,
        height: 48,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final String label;
  final bool accent;
  final VoidCallback onTap;

  const _SheetAction({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: accent ? const Color(0xFF2A1218) : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: accent ? const Color(0xFFC63C54) : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
