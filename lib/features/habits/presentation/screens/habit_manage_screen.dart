import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/core/ui/icon_mapper.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/domain/entities/habit_stats.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

class HabitManageScreen extends ConsumerWidget {
  final String habitId;
  final int initialTab;

  const HabitManageScreen({
    super.key,
    required this.habitId,
    this.initialTab = 0,
  });

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
      initialIndex: initialTab.clamp(0, 2),
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
                child: Text(
                  'Hábito no encontrado.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return TabBarView(
              children: [
                _ManageCalendarTab(habit: habit!),
                stats.when(
                  data: (s) => _StatsContent(stats: s),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                HabitEditTab(habit: habit!),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageCalendarTab extends ConsumerStatefulWidget {
  final Habit habit;

  const _ManageCalendarTab({required this.habit});

  @override
  ConsumerState<_ManageCalendarTab> createState() => _ManageCalendarTabState();
}

class _ManageCalendarTabState extends ConsumerState<_ManageCalendarTab> {
  late DateTime _visibleMonth;
  late final PageController _monthPageController;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _monthPageController = PageController(initialPage: 1);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _monthPageController.dispose();
    super.dispose();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = nextLogicalDayBoundary(now);
    _midnightTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {
        final nowDate = logicalDateFromDateTime(DateTime.now());
        _visibleMonth = DateTime(nowDate.year, nowDate.month);
      });
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _toggle(DateTime date, bool isDone) async {
    final key = dateKeyFromDateTime(date);
    if (isDone) {
      final unmark = await ref.read(unmarkHabitDoneProvider.future);
      await unmark(widget.habit.id, key);
      return;
    }
    final mark = await ref.read(markHabitDoneProvider.future);
    await mark(widget.habit.id, key, source: 'manage_calendar');
  }

  @override
  Widget build(BuildContext context) {
    final monthCompletions = ref.watch(
      habitMonthCompletionsProvider(
        (habitId: widget.habit.id, month: _visibleMonth),
      ),
    );
    final prevMonthCompletions = ref.watch(
      habitMonthCompletionsProvider(
        (
          habitId: widget.habit.id,
          month: DateTime(_visibleMonth.year, _visibleMonth.month - 1),
        ),
      ),
    );
    final nextMonthCompletions = ref.watch(
      habitMonthCompletionsProvider(
        (
          habitId: widget.habit.id,
          month: DateTime(_visibleMonth.year, _visibleMonth.month + 1),
        ),
      ),
    );
    final stats = ref.watch(habitStatsProvider(widget.habit.id));
    if (monthCompletions.isLoading ||
        prevMonthCompletions.isLoading ||
        nextMonthCompletions.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (monthCompletions.hasError ||
        prevMonthCompletions.hasError ||
        nextMonthCompletions.hasError) {
      return Center(
        child: Text(
          'Error: ${monthCompletions.error ?? prevMonthCompletions.error ?? nextMonthCompletions.error}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return PageView(
      controller: _monthPageController,
      onPageChanged: (page) {
        if (page == 1) return;
        setState(() {
          _visibleMonth = DateTime(
            _visibleMonth.year,
            _visibleMonth.month + (page == 2 ? 1 : -1),
          );
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _monthPageController.hasClients) {
            _monthPageController.jumpToPage(1);
          }
        });
      },
      children: [
        _ManageCalendarContent(
          habit: widget.habit,
          visibleMonth: DateTime(_visibleMonth.year, _visibleMonth.month - 1),
          doneKeys: (prevMonthCompletions.asData?.value ?? const [])
              .map((e) => e.dateKey)
              .toSet(),
          streakDays: stats.asData?.value.currentStreak ?? 0,
          onPrev: () => _monthPageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onNext: () => _monthPageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onToggle: _toggle,
        ),
        _ManageCalendarContent(
          habit: widget.habit,
          visibleMonth: _visibleMonth,
          doneKeys: (monthCompletions.asData?.value ?? const [])
              .map((e) => e.dateKey)
              .toSet(),
          streakDays: stats.asData?.value.currentStreak ?? 0,
          onPrev: () => _monthPageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onNext: () => _monthPageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onToggle: _toggle,
        ),
        _ManageCalendarContent(
          habit: widget.habit,
          visibleMonth: DateTime(_visibleMonth.year, _visibleMonth.month + 1),
          doneKeys: (nextMonthCompletions.asData?.value ?? const [])
              .map((e) => e.dateKey)
              .toSet(),
          streakDays: stats.asData?.value.currentStreak ?? 0,
          onPrev: () => _monthPageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onNext: () => _monthPageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
          onToggle: _toggle,
        ),
      ],
    );
  }
}

class _ManageCalendarContent extends StatelessWidget {
  final Habit habit;
  final DateTime visibleMonth;
  final Set<String> doneKeys;
  final int streakDays;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Future<void> Function(DateTime, bool) onToggle;

  const _ManageCalendarContent({
    required this.habit,
    required this.visibleMonth,
    required this.doneKeys,
    required this.streakDays,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final monthGrid = _buildMonthGrid(visibleMonth);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPrev,
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFFC63C54),
                    size: 26,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _monthName(visibleMonth.month),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${visibleMonth.year}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFC63C54),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _ManageWeekdayHeader(),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthGrid.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final date = monthGrid[index];
                final dateKey = dateKeyFromDateTime(date);
                final inMonth = date.month == visibleMonth.month;
                final isDone = doneKeys.contains(dateKey);
                final now = logicalDateFromDateTime(DateTime.now());
                final isToday =
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
                final isFuture = DateTime(
                  date.year,
                  date.month,
                  date.day,
                ).isAfter(DateTime(now.year, now.month, now.day));
                return GestureDetector(
                  onTap: () async {
                    if (!inMonth || isFuture) return;
                    await onToggle(date, isDone);
                  },
                  child: _ManageDayCell(
                    day: date.day,
                    inMonth: inMonth,
                    isDone: isDone,
                    isToday: isToday,
                    isFuture: isFuture,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ManageInfoCard(
          icon: Icons.link,
          label: 'Racha',
          content: '$streakDays DÍAS',
          contentColor: const Color(0xFFC63C54),
        ),
        const SizedBox(height: 10),
        _ManageInfoCard(
          icon: Icons.info_outline,
          label: 'Descripción',
          content: (habit.description?.trim().isNotEmpty ?? false)
              ? habit.description!.trim()
              : 'Sin descripción',
        ),
        const SizedBox(height: 10),
        const _ManageInfoCard(
          icon: Icons.chat_bubble_outline,
          label: 'Notas',
          content: 'Sin notas para este mes',
        ),
      ],
    );
  }
}

class _ManageWeekdayHeader extends StatelessWidget {
  const _ManageWeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: (label == 'Dom' || label == 'Sáb')
                        ? const Color(0xFFC63C54)
                        : Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ManageDayCell extends StatelessWidget {
  final int day;
  final bool inMonth;
  final bool isDone;
  final bool isToday;
  final bool isFuture;

  const _ManageDayCell({
    required this.day,
    required this.inMonth,
    required this.isDone,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    const doneColor = Color(0xFFFFB400);
    const todayColor = Color(0xFFC63C54);
    Color border = Colors.transparent;
    if (inMonth) {
      if (isDone) {
        border = doneColor;
      } else if (isToday) {
        border = todayColor;
      } else if (isFuture) {
        border = const Color(0xFF252933);
      } else {
        border = const Color(0xFF2A2E38);
      }
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 2),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: !inMonth
                ? Colors.white24
                : isFuture
                    ? Colors.white38
                    : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ManageInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;
  final Color contentColor;

  const _ManageInfoCard({
    required this.icon,
    required this.label,
    required this.content,
    this.contentColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1015),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF171A21)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFC63C54), size: 22),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: contentColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

List<DateTime> _buildMonthGrid(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final firstWeekdayMondayBased = first.weekday - 1;
  final start = first.subtract(Duration(days: firstWeekdayMondayBased));
  return List.generate(42, (i) => start.add(Duration(days: i)));
}

String _monthName(int month) {
  switch (month) {
    case 1:
      return 'Enero';
    case 2:
      return 'Febrero';
    case 3:
      return 'Marzo';
    case 4:
      return 'Abril';
    case 5:
      return 'Mayo';
    case 6:
      return 'Junio';
    case 7:
      return 'Julio';
    case 8:
      return 'Agosto';
    case 9:
      return 'Septiembre';
    case 10:
      return 'Octubre';
    case 11:
      return 'Noviembre';
    case 12:
      return 'Diciembre';
    default:
      return '';
  }
}

class HabitEditTab extends ConsumerWidget {
  final Habit habit;

  const HabitEditTab({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFFC63C54);
    const surface = Color(0xFF141414);
    const dividerColor = Color(0xFF1F1F1F);
    final reminderCount =
        habit.reminderTimes?.length ?? habit.reminderCount ?? 0;
    final priority = habit.priority ?? 1;
    final description =
        (habit.description == null || habit.description!.trim().isEmpty)
        ? 'Sin descripción'
        : habit.description!.trim();
    final haId = (habit.haId == null || habit.haId!.trim().isEmpty)
        ? 'Sin HA ID'
        : habit.haId!.trim();
    final categoryLabel =
        (habit.categoryLabel == null || habit.categoryLabel!.trim().isEmpty)
        ? 'Sin categoría'
        : habit.categoryLabel!.trim();
    final categoryColor = habit.categoryColor != null
        ? Color(habit.categoryColor!)
        : const Color(0xFF2A2A2A);
    final categoryLabelColor = categoryLabel == 'Sin categoría'
        ? Colors.white38
        : Colors.orangeAccent;
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
          icon: Icons.link,
          title: 'HA ID',
          onTap: () => _editHaId(context, ref),
          trailing: Text(
            haId,
            style: TextStyle(
              color: haId == 'Sin HA ID' ? Colors.white38 : Colors.white70,
            ),
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
                  style: const TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
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
          trailing: Text(
            frequencyLabel,
            style: const TextStyle(color: Colors.white54),
          ),
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
              _DatePill(
                text: habit.endDate == null ? '-' : _formatDate(habit.endDate),
              ),
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
        Container(height: 1, color: surface),
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
    if (!context.mounted) return;
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

  Future<void> _editHaId(BuildContext context, WidgetRef ref) async {
    final result = await _showTextDialog(
      context,
      title: 'HA ID',
      initialValue: habit.haId ?? '',
    );
    if (result == null) return;
    final updater = await ref.read(updateHabitProvider.future);
    await updater(
      habitId: habit.id,
      haId: result,
      setHaId: true,
    );
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
          separatorBuilder:
              (context, index) => const Divider(color: Color(0xFF2A2A2A)),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.white38,
                ),
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
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white38,
                                    ),
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
                        initialTime: _parseTime(
                          times.isNotEmpty ? times.last : '08:00',
                        ),
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
          separatorBuilder:
              (context, index) => const Divider(color: Color(0xFF2A2A2A)),
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
    if (!context.mounted) return;
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
              hintText: multiline
                  ? 'Escribe una descripción'
                  : 'Escribe un nombre',
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
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text(
                'GUARDAR',
                style: TextStyle(color: Color(0xFFC63C54)),
              ),
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
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(color: Color(0xFFC63C54)),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  const _AccentSquare({required this.iconCodePoint, required this.color});

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
      child: Text(
        text,
        style: const TextStyle(color: accent, fontWeight: FontWeight.w600),
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
        style: const TextStyle(color: accent, fontWeight: FontWeight.w600),
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
            _StatTile(
              label: 'Racha actual',
              value: stats.currentStreak.toString(),
              color: card,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Racha máx',
              value: stats.maxStreak.toString(),
              color: card,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatTile(
              label: '7 días',
              value: _percent(stats.percent7),
              color: card,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: '30 días',
              value: _percent(stats.percent30),
              color: card,
            ),
            const SizedBox(width: 12),
            _StatTile(
              label: '90 días',
              value: _percent(stats.percent90),
              color: card,
            ),
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
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
