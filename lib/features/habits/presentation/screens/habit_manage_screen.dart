import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/core/ui/icon_mapper.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/domain/entities/habit_stats.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

class HabitManageScreen extends ConsumerWidget {
  final String habitId;

  const HabitManageScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(watchActiveHabitsProvider);
    final stats = ref.watch(habitStatsProvider(habitId));

    Habit? habit;
    habits.whenData((items) {
      for (final h in items) {
        if (h.id == habitId) {
          habit = h;
          break;
        }
      }
    });

    const background = Color(0xFF111111);
    const accent = Color(0xFFC63C54);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left, color: accent),
          ),
          title: Row(
            children: [
              if (habit != null) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(habit!.color).withValues(alpha: 0.25),
                  child: Icon(
                    iconFromName(habit!.icon),
                    size: 16,
                    color: Color(habit!.color),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  habit?.name ?? 'Hábito',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: accent),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: accent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: 'Calendario'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Editar'),
            ],
          ),
        ),
        body: habits.when(
          data: (_) {
            if (habit == null) {
              return const Center(
                child: Text('Hábito no encontrado.', style: TextStyle(color: Colors.white70)),
              );
            }
            return TabBarView(
              children: [
                const _CalendarPlaceholder(),
                stats.when(
                  data: (s) => _StatsContent(stats: s),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Error: $err', style: const TextStyle(color: Colors.white70)),
                  ),
                ),
                _HabitEditTab(habit: habit!),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Error: $err', style: const TextStyle(color: Colors.white70)),
          ),
        ),
      ),
    );
  }
}

class _CalendarPlaceholder extends StatelessWidget {
  const _CalendarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Calendario próximamente',
        style: TextStyle(color: Colors.white60),
      ),
    );
  }
}

class _HabitEditTab extends ConsumerWidget {
  final Habit habit;

  const _HabitEditTab({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFFC63C54);
    const surface = Color(0xFF141414);
    const dividerColor = Color(0xFF1F1F1F);
    final reminderCount = habit.reminderTimes?.length ?? habit.reminderCount ?? 0;
    final priority = habit.priority ?? 1;
    final description =
        (habit.description == null || habit.description!.trim().isEmpty)
            ? 'Sin descripción'
            : habit.description!.trim();
    final categoryLabel =
        (habit.categoryLabel == null || habit.categoryLabel!.trim().isEmpty)
            ? 'Sin categoría'
            : habit.categoryLabel!.trim();
    final categoryColor = habit.categoryColor != null
        ? Color(habit.categoryColor!)
        : const Color(0xFF2A2A2A);
    final categoryLabelColor =
        categoryLabel == 'Sin categoría' ? Colors.white38 : Colors.orangeAccent;
    final frequencyLabel =
        (habit.frequencyLabel == null || habit.frequencyLabel!.trim().isEmpty)
            ? 'Cada día'
            : habit.frequencyLabel!.trim();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _EditRow(
          icon: Icons.edit,
          title: 'Nombre del hábito',
          onTap: () => _editName(context, ref),
          trailing: Text(
            habit.name,
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.category,
          title: 'Categoría',
          onTap: () => _editCategory(context, ref),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(categoryLabel, style: TextStyle(color: categoryLabelColor)),
              const SizedBox(width: 10),
              _AccentSquare(
                iconCodePoint: habit.categoryIconCodePoint,
                color: categoryColor,
              ),
            ],
          ),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.info_outline,
          title: 'Descripción',
          onTap: () => _editDescription(context, ref),
          trailing: Text(
            description,
            style: TextStyle(
              color: description == 'Sin descripción'
                  ? Colors.white38
                  : Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.notifications_none,
          title: 'Hora y recordatorios',
          onTap: () => _editReminderTimes(context, ref),
          trailing: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2A0F17),
              shape: BoxShape.circle,
            ),
            child: Text(
              reminderCount.toString(),
              style: const TextStyle(color: accent),
            ),
          ),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.flag_outlined,
          title: 'Prioridad',
          onTap: () => _editPriority(context, ref, priority),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A0F17),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  priority.toString(),
                  style: const TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.flag, size: 16, color: accent),
              ],
            ),
          ),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.repeat,
          title: 'Frecuencia',
          onTap: () => _editFrequency(context, ref),
          trailing: Text(frequencyLabel, style: const TextStyle(color: Colors.white54)),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.event,
          title: 'Fecha de inicio',
          onTap: () => _editStartDate(context, ref),
          trailing: _DatePill(text: _formatDate(habit.startDate)),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.event,
          title: 'Fecha de fin',
          onTap: () => _editEndDate(context, ref),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DatePill(text: habit.endDate == null ? '-' : _formatDate(habit.endDate)),
              if (habit.endDate != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _clearEndDate(context, ref),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline, color: Colors.white38),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.archive_outlined,
          title: 'Archivar',
          onTap: () => _archiveHabit(context, ref),
          trailing: const SizedBox.shrink(),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.restart_alt,
          title: 'Reiniciar progreso del hábito',
          onTap: () => _resetProgress(context, ref),
          trailing: const SizedBox.shrink(),
        ),
        const Divider(color: dividerColor, height: 28),
        _EditRow(
          icon: Icons.delete_outline,
          title: 'Eliminar hábito',
          onTap: () => _deleteHabit(context, ref),
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: surface,
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final result = await _showTextDialog(
      context,
      title: 'Nombre del hábito',
      initialValue: habit.name,
    );
    if (result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      _showMessage(context, 'El nombre no puede estar vacío.');
      return;
    }
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, name: trimmed);
  }

  Future<void> _editDescription(BuildContext context, WidgetRef ref) async {
    final result = await _showTextDialog(
      context,
      title: 'Descripción',
      initialValue: habit.description ?? '',
      multiline: true,
    );
    if (result == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, description: result);
  }

  Future<void> _editCategory(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<_CategoryOption>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final options = _categoryOptions();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          shrinkWrap: true,
          itemCount: options.length + 1,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A)),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: Colors.white38),
                title: const Text(
                  'Sin categoría',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => Navigator.of(context).pop(null),
              );
            }
            final option = options[index - 1];
            return ListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(option.icon, color: Colors.black87, size: 18),
              ),
              title: Text(
                option.label,
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () => Navigator.of(context).pop(option),
            );
          },
        );
      },
    );
    final updater = await ref.read(updateHabitProvider.future);
    if (selected == null) {
      await updater(
        habitId: habit.id,
        categoryLabel: '',
        categoryColor: null,
        categoryIconCodePoint: null,
      );
      return;
    }
    await updater(
      habitId: habit.id,
      categoryLabel: selected.label,
      categoryColor: selected.color.toARGB32(),
      categoryIconCodePoint: selected.icon.codePoint,
    );
  }

  Future<void> _editReminderTimes(BuildContext context, WidgetRef ref) async {
    final initial = List<String>.from(habit.reminderTimes ?? const []);
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        var times = List<String>.from(initial);
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Recordatorios',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (times.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Sin recordatorios',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Column(
                      children: times
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  _Pill(text: t),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        times.remove(t);
                                      });
                                    },
                                    icon: const Icon(Icons.close,
                                        color: Colors.white38),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  _SheetAction(
                    label: 'AGREGAR HORA',
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _parseTime(times.isNotEmpty
                            ? times.last
                            : '08:00'),
                      );
                      if (picked == null) return;
                      final value = _formatTime(picked);
                      setState(() {
                        if (!times.contains(value)) {
                          times.add(value);
                          times.sort();
                        }
                      });
                    },
                    accent: true,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetAction(
                          label: 'CANCELAR',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetAction(
                          label: 'GUARDAR',
                          accent: true,
                          onTap: () => Navigator.of(context).pop(times),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (updated == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(
      habitId: habit.id,
      reminderTimes: updated.isEmpty ? null : updated,
      setReminderTimes: true,
    );
  }

  Future<void> _editPriority(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    var temp = current;
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
                      label: 'CANCELAR',
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
    if (result == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, priority: result);
  }

  Future<void> _editFrequency(BuildContext context, WidgetRef ref) async {
    final options = const [
      'Cada día',
      'Días específicos de la semana',
      'Días específicos del mes',
      'Días específicos del año',
      'Algunos días por periodo',
      'Repetir',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          shrinkWrap: true,
          itemCount: options.length,
          separatorBuilder: (_, __) => const Divider(color: Color(0xFF2A2A2A)),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                options[index],
                style: const TextStyle(color: Colors.white70),
              ),
              onTap: () => Navigator.of(context).pop(options[index]),
            );
          },
        );
      },
    );
    if (selected == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, frequencyLabel: selected);
  }

  Future<void> _editStartDate(BuildContext context, WidgetRef ref) async {
    final initial = habit.startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, startDate: picked);
  }

  Future<void> _editEndDate(BuildContext context, WidgetRef ref) async {
    final initial = habit.endDate ?? habit.startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, endDate: picked, setEndDate: true);
  }

  Future<void> _clearEndDate(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Quitar fecha de fin',
      message: 'Esto eliminará la fecha de fin del hábito.',
    );
    if (!confirm) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, endDate: null, setEndDate: true);
  }

  Future<void> _archiveHabit(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Archivar hábito',
      message: 'El hábito se ocultará de la lista activa.',
    );
    if (!confirm) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(habitId: habit.id, active: false);
    if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _resetProgress(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Reiniciar progreso',
      message: 'Esto eliminará todos los completados de este hábito.',
    );
    if (!confirm) return;
    final resetter = await ref.read(resetHabitProgressProvider.future);
    await resetter(habit.id);
    _showMessage(context, 'Progreso reiniciado.');
  }

  Future<void> _deleteHabit(BuildContext context, WidgetRef ref) async {
    final confirm = await _confirm(
      context,
      title: 'Eliminar hábito',
      message: 'Esto eliminará el hábito y su historial.',
    );
    if (!confirm) return;
    final deleter = await ref.read(deleteHabitProvider.future);
    await deleter(habit.id);
    if (context.mounted) {
      context.pop();
    }
  }

  Future<String?> _showTextDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    bool multiline = false,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: multiline ? 4 : 1,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: multiline ? 'Escribe una descripción' : 'Escribe un nombre',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFC63C54)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('GUARDAR', style: TextStyle(color: Color(0xFFC63C54))),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONFIRMAR', style: TextStyle(color: Color(0xFFC63C54))),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _EditRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _EditRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(child: trailing),
          ],
        ),
      ),
    );
  }
}

class _AccentSquare extends StatelessWidget {
  final int? iconCodePoint;
  final Color color;

  const _AccentSquare({
    required this.iconCodePoint,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = iconCodePoint == null
        ? Icons.cut
        : IconData(iconCodePoint!, fontFamily: 'MaterialIcons');
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.black87, size: 18),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String text;

  const _DatePill({required this.text});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0F17),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: accent, fontWeight: FontWeight.w600)),
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

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString();
  final year = (date.year % 100).toString().padLeft(2, '0');
  return '$day/$month/$year';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

List<_CategoryOption> _categoryOptions() {
  return const [
    _CategoryOption('Dejar un mal hábito', Icons.block, Color(0xFFE24B3C)),
    _CategoryOption('Arte', Icons.brush, Color(0xFFFF3B5B)),
    _CategoryOption('Meditación', Icons.self_improvement, Color(0xFFD44BC4)),
    _CategoryOption('Estudio', Icons.school, Color(0xFF8E5CF6)),
    _CategoryOption('Deportes', Icons.pedal_bike, Color(0xFF4F79F6)),
    _CategoryOption('Entretenimiento', Icons.movie, Color(0xFF00B3C7)),
    _CategoryOption('Social', Icons.forum, Color(0xFF14B89A)),
    _CategoryOption('Finanzas', Icons.attach_money, Color(0xFF17B86D)),
    _CategoryOption('Salud', Icons.add, Color(0xFF7FC34A)),
    _CategoryOption('Trabajo', Icons.work, Color(0xFF99B01F)),
    _CategoryOption('Nutrición', Icons.restaurant, Color(0xFFF4B23C)),
    _CategoryOption('Hogar', Icons.home, Color(0xFFF28E2B)),
    _CategoryOption('Al aire libre', Icons.terrain, Color(0xFFE46E2E)),
    _CategoryOption('Otro', Icons.category, Color(0xFFE64B2E)),
  ];
}

class _CategoryOption {
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryOption(this.label, this.icon, this.color);
}

class _StatsContent extends StatelessWidget {
  final HabitStats stats;

  const _StatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    const card = Color(0xFF1C1C1C);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _StatTile(label: 'Racha actual', value: stats.currentStreak.toString(), color: card),
            const SizedBox(width: 12),
            _StatTile(label: 'Racha máx', value: stats.maxStreak.toString(), color: card),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(label: '7 días', value: _percent(stats.percent7), color: card),
            const SizedBox(width: 12),
            _StatTile(label: '30 días', value: _percent(stats.percent30), color: card),
            const SizedBox(width: 12),
            _StatTile(label: '90 días', value: _percent(stats.percent90), color: card),
          ],
        ),
      ],
    );
  }

  String _percent(double value) => '${(value * 100).round()}%';
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
