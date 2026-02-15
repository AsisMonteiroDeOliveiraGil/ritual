import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

enum _HabitsFilterTab { all, daily, weekly, monthly }

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  List<Habit> _ordered = const [];
  final Map<String, int> _weekOffsetByHabit = <String, int>{};
  int _lastResetSignal = 0;
  String? _expandedHabitId;
  _HabitsFilterTab _selectedFilterTab = _HabitsFilterTab.all;
  final Map<String, DateTime> _expandedMonths = <String, DateTime>{};

  bool _isDailyHabit(Habit habit) {
    final raw = habit.frequencyLabel?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return true;
    return raw == 'cada día' || raw == 'cada dia' || raw == 'diario';
  }

  bool _isWeeklyHabit(Habit habit) {
    final raw = habit.frequencyLabel?.trim().toLowerCase() ?? '';
    return raw.contains('semana');
  }

  bool _isMonthlyHabit(Habit habit) {
    final raw = habit.frequencyLabel?.trim().toLowerCase() ?? '';
    return raw.contains('mes');
  }

  List<Habit> _filterHabits(List<Habit> source) {
    switch (_selectedFilterTab) {
      case _HabitsFilterTab.all:
        return source;
      case _HabitsFilterTab.daily:
        return source.where(_isDailyHabit).toList();
      case _HabitsFilterTab.weekly:
        return source.where(_isWeeklyHabit).toList();
      case _HabitsFilterTab.monthly:
        return source.where(_isMonthlyHabit).toList();
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final updated = List<Habit>.from(_ordered);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    setState(() => _ordered = updated);

    final updater = await ref.read(updateHabitProvider.future);
    for (var i = 0; i < updated.length; i++) {
      final targetOrder = i + 1;
      final habit = updated[i];
      if (habit.order != targetOrder) {
        await updater(habitId: habit.id, order: targetOrder, setOrder: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFF0B0D11);
    const cardBg = Color(0xFF191C21);
    const accent = Color(0xFFC63C54);

    final habits = ref.watch(watchActiveHabitsProvider);
    final resetSignal = ref.watch(habitsWeekResetSignalProvider);
    if (resetSignal != _lastResetSignal) {
      _lastResetSignal = resetSignal;
      _weekOffsetByHabit.clear();
    }
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: accent, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Hábitos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/habit/new'),
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Nuevo hábito',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _HabitsFilterTabs(
                selected: _selectedFilterTab,
                onChanged: (tab) {
                  setState(() {
                    _selectedFilterTab = tab;
                  });
                },
              ),
            ),
            Expanded(
              child: habits.when(
                data: (items) {
                  final next = [...items]
                    ..sort((a, b) => a.order.compareTo(b.order));
                  final sameSequence =
                      _ordered.length == next.length &&
                      _ordered.asMap().entries.every(
                        (entry) => entry.value.id == next[entry.key].id,
                      );
                  if (!sameSequence) {
                    _ordered = next;
                  }
                  final visibleHabits = _filterHabits(_ordered);
                  final canReorder = _selectedFilterTab == _HabitsFilterTab.all;

                  if (_ordered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay hábitos activos.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  if (visibleHabits.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay hábitos en este filtro.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  Widget buildHabitCard(Habit habit, int index) {
                      final isExpanded = _expandedHabitId == habit.id;
                      final cardWeekOffset = _weekOffsetByHabit[habit.id] ?? 0;
                      final expandedMonth =
                          _expandedMonths[habit.id] ??
                          DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                          );
                      final completions = ref.watch(
                        habitWeekCompletionsByOffsetProvider((
                          habitId: habit.id,
                          weekOffset: cardWeekOffset,
                        )),
                      );
                      final monthCompletions = isExpanded
                          ? ref.watch(
                              habitMonthCompletionsProvider((
                                habitId: habit.id,
                                month: expandedMonth,
                              )),
                            )
                          : null;
                      return Padding(
                        key: ValueKey(habit.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: canReorder
                              ? ReorderableDelayedDragStartListener(
                                  index: index,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () =>
                                          context.push('/habit/${habit.id}'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    14,
                                                    12,
                                                    14,
                                                    6,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            habit.name,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  letterSpacing:
                                                                      -0.1,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        _TypePill(
                                                          label:
                                                              _habitTypeLabel(
                                                                habit,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            completions.when(
                                              data: (list) {
                                                if (!isExpanded) {
                                                  return _WeekStrip(
                                                    completions: list,
                                                    highlightColor: Color(
                                                      habit.color,
                                                    ),
                                                    startDate: habit.startDate,
                                                    weekOffset: cardWeekOffset,
                                                    expanded: false,
                                                    onWeekOffsetChange: (delta) {
                                                      setState(() {
                                                        _weekOffsetByHabit[habit.id] =
                                                            cardWeekOffset + delta;
                                                      });
                                                    },
                                                  );
                                                }
                                                return monthCompletions!.when(
                                                  data: (monthList) => _WeekStrip(
                                                    completions: list,
                                                    highlightColor: Color(
                                                      habit.color,
                                                    ),
                                                    startDate: habit.startDate,
                                                    weekOffset: cardWeekOffset,
                                                    expanded: true,
                                                    expandedMonth:
                                                        expandedMonth,
                                                    expandedDoneKeys: monthList
                                                        .map((e) => e.dateKey)
                                                        .toSet(),
                                                    onPrevMonth: () {
                                                      setState(() {
                                                        _expandedMonths[habit.id] = DateTime(
                                                          expandedMonth.year,
                                                          expandedMonth.month - 1,
                                                        );
                                                      });
                                                    },
                                                    onNextMonth: () {
                                                      setState(() {
                                                        _expandedMonths[habit.id] = DateTime(
                                                          expandedMonth.year,
                                                          expandedMonth.month + 1,
                                                        );
                                                      });
                                                    },
                                                  ),
                                                  loading: () => const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 24,
                                                        ),
                                                    child: SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ),
                                                  error: (err, _) =>
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 20,
                                                            ),
                                                        child: Text(
                                                          'Error al cargar calendario',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        ),
                                                      ),
                                                );
                                              },
                                              loading: () => const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 20,
                                                ),
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                              error: (err, _) => const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 20,
                                                ),
                                                child: Icon(
                                                  Icons.error,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            ),
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFF262A31),
                                            ),
                                            completions.when(
                                              data: (list) => _CardFooter(
                                                completions: list,
                                                startDate: habit.startDate,
                                                weekOffset: cardWeekOffset,
                                                isExpanded: isExpanded,
                                                onToggleExpand: () {
                                                  setState(() {
                                                    if (isExpanded) {
                                                      _expandedHabitId = null;
                                                    } else {
                                                      _expandedHabitId = habit.id;
                                                      _expandedMonths[habit.id] =
                                                          expandedMonth;
                                                    }
                                                  });
                                                },
                                              ),
                                              loading: () =>
                                                  const SizedBox(height: 46),
                                              error: (err, _) =>
                                                  const SizedBox(height: 46),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        context.push('/habit/${habit.id}'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          12,
                                          14,
                                          6,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      habit.name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: -0.1,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _TypePill(
                                                    label: _habitTypeLabel(
                                                      habit,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      completions.when(
                                        data: (list) {
                                          if (!isExpanded) {
                                            return _WeekStrip(
                                              completions: list,
                                              highlightColor: Color(habit.color),
                                              startDate: habit.startDate,
                                              weekOffset: cardWeekOffset,
                                              expanded: false,
                                              onWeekOffsetChange: (delta) {
                                                setState(() {
                                                  _weekOffsetByHabit[habit.id] =
                                                      cardWeekOffset + delta;
                                                });
                                              },
                                            );
                                          }
                                          return monthCompletions!.when(
                                            data: (monthList) => _WeekStrip(
                                              completions: list,
                                              highlightColor: Color(habit.color),
                                              startDate: habit.startDate,
                                              weekOffset: cardWeekOffset,
                                              expanded: true,
                                              expandedMonth: expandedMonth,
                                              expandedDoneKeys: monthList
                                                  .map((e) => e.dateKey)
                                                  .toSet(),
                                              onPrevMonth: () {
                                                setState(() {
                                                  _expandedMonths[habit.id] = DateTime(
                                                    expandedMonth.year,
                                                    expandedMonth.month - 1,
                                                  );
                                                });
                                              },
                                              onNextMonth: () {
                                                setState(() {
                                                  _expandedMonths[habit.id] = DateTime(
                                                    expandedMonth.year,
                                                    expandedMonth.month + 1,
                                                  );
                                                });
                                              },
                                            ),
                                            loading: () => const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 24,
                                              ),
                                              child: SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                            error: (err, _) => const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 20,
                                              ),
                                              child: Text(
                                                'Error al cargar calendario',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        loading: () => const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        error: (err, _) => const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                      const Divider(
                                        height: 1,
                                        color: Color(0xFF262A31),
                                      ),
                                      completions.when(
                                        data: (list) => _CardFooter(
                                          completions: list,
                                          startDate: habit.startDate,
                                          weekOffset: cardWeekOffset,
                                          isExpanded: isExpanded,
                                          onToggleExpand: () {
                                            setState(() {
                                              if (isExpanded) {
                                                _expandedHabitId = null;
                                              } else {
                                                _expandedHabitId = habit.id;
                                                _expandedMonths[habit.id] =
                                                    expandedMonth;
                                              }
                                            });
                                          },
                                        ),
                                        loading: () =>
                                            const SizedBox(height: 46),
                                        error: (err, _) =>
                                            const SizedBox(height: 46),
                                      ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                      );
                    }

                  if (canReorder) {
                    return ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      buildDefaultDragHandles: false,
                      itemCount: visibleHabits.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.02).animate(animation),
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) =>
                          buildHabitCard(visibleHabits[index], index),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: visibleHabits.length,
                    itemBuilder: (context, index) =>
                        buildHabitCard(visibleHabits[index], index),
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
          ],
        ),
      ),
    );
  }
}

String _habitTypeLabel(Habit habit) {
  final raw = habit.frequencyLabel?.trim() ?? '';
  if (raw.isEmpty) return 'Diario';
  final lowered = raw.toLowerCase();
  if (lowered == 'cada día' || lowered == 'cada dia' || lowered == 'diario') {
    return 'Diario';
  }
  return raw;
}

class _HabitsFilterTabs extends StatelessWidget {
  final _HabitsFilterTab selected;
  final ValueChanged<_HabitsFilterTab> onChanged;

  const _HabitsFilterTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF151920);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF252A33)),
      ),
      child: Row(
        children: [
          _FilterTabButton(
            label: 'Todos',
            active: selected == _HabitsFilterTab.all,
            onTap: () => onChanged(_HabitsFilterTab.all),
          ),
          _FilterTabButton(
            label: 'Diario',
            active: selected == _HabitsFilterTab.daily,
            onTap: () => onChanged(_HabitsFilterTab.daily),
          ),
          _FilterTabButton(
            label: 'Semanal',
            active: selected == _HabitsFilterTab.weekly,
            onTap: () => onChanged(_HabitsFilterTab.weekly),
          ),
          _FilterTabButton(
            label: 'Mensual',
            active: selected == _HabitsFilterTab.monthly,
            onTap: () => onChanged(_HabitsFilterTab.monthly),
          ),
        ],
      ),
    );
  }
}

class _FilterTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC63C54) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 34,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;

  const _TypePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF223126),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF67D140),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WeekStrip extends StatefulWidget {
  final List<Completion> completions;
  final Color highlightColor;
  final DateTime? startDate;
  final int weekOffset;
  final bool expanded;
  final DateTime? expandedMonth;
  final Set<String>? expandedDoneKeys;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  final ValueChanged<int>? onWeekOffsetChange;

  const _WeekStrip({
    required this.completions,
    required this.highlightColor,
    this.startDate,
    this.weekOffset = 0,
    this.expanded = false,
    this.expandedMonth,
    this.expandedDoneKeys,
    this.onPrevMonth,
    this.onNextMonth,
    this.onWeekOffsetChange,
  });

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  late final PageController _pageController;
  bool _applyingWeekChange = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _keysForOffset(int offset) {
    final refNow = logicalDateFromDateTime(
      DateTime.now(),
    ).add(Duration(days: offset * 7));
    final monday = DateTime(
      refNow.year,
      refNow.month,
      refNow.day,
    ).subtract(Duration(days: refNow.weekday - 1));
    return List<String>.generate(
      7,
      (i) => dateKeyFromDateTime(monday.add(Duration(days: i))),
    );
  }

  Widget _buildWeekRow({
    required BuildContext context,
    required List<String> keys,
    required Set<String> done,
    required DateTime? normalizedStartDate,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const itemSpacing = 4.0;
          final rawWidth = (constraints.maxWidth - (itemSpacing * 6)) / 7;
          final circleSize = rawWidth.clamp(26.0, 38.0);
          final dayFontSize = (circleSize * 0.48).clamp(12.0, 18.0);
          final circleRadius = (circleSize * 0.42).clamp(10.0, 14.0);

          return Row(
            children: keys.asMap().entries.map((entry) {
              final index = entry.key;
              final key = entry.value;
              final date = dateFromDateKey(key);
              final isBeforeStart =
                  normalizedStartDate != null &&
                  DateTime(date.year, date.month, date.day).isBefore(
                    normalizedStartDate,
                  );
              final isDone = done.contains(key);
              final logicalTodayKey = logicalDateKeyFromNow();
              final isPastNotDone =
                  !isBeforeStart && !isDone && key.compareTo(logicalTodayKey) < 0;
              final borderColor = isDone
                  ? const Color(0xFF00C565)
                  : isBeforeStart
                  ? Colors.transparent
                  : isPastNotDone
                  ? const Color(0xFFFF3366)
                  : const Color(0xFF2A2E38);
              final textColor = isDone
                  ? Colors.white
                  : isBeforeStart
                  ? Colors.white24
                  : Colors.white;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == keys.length - 1 ? 0 : itemSpacing,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weekdayShort(date.weekday),
                        style: TextStyle(
                          color:
                              date.weekday == DateTime.saturday ||
                                  date.weekday == DateTime.sunday
                              ? const Color(0xFFC63C54)
                              : Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      isBeforeStart
                          ? SizedBox(
                              width: circleSize,
                              height: circleSize,
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: dayFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  circleRadius,
                                ),
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: dayFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.completions.map((c) => c.dateKey).toSet();
    final normalizedStartDate = widget.startDate == null
        ? null
        : DateTime(
            widget.startDate!.year,
            widget.startDate!.month,
            widget.startDate!.day,
          );

    if (widget.expanded) {
      final month = widget.expandedMonth ??
          DateTime(DateTime.now().year, DateTime.now().month);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final first = DateTime(month.year, month.month, 1);
      final leading = first.weekday - 1;
      final cells = leading + daysInMonth;
      final trailing = (7 - (cells % 7)) % 7;
      final total = cells + trailing;
      final monthDone = widget.expandedDoneKeys ?? const <String>{};

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onPrevMonth,
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
                        _monthName(month.month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${month.year}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onNextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFC63C54),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                _MonthWeekLabel('Lun'),
                _MonthWeekLabel('Mar'),
                _MonthWeekLabel('Mié'),
                _MonthWeekLabel('Jue'),
                _MonthWeekLabel('Vie'),
                _MonthWeekLabel('Sáb', isWeekend: true),
                _MonthWeekLabel('Dom', isWeekend: true),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: total,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                if (index < leading || index >= leading + daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = index - leading + 1;
                final date = DateTime(month.year, month.month, day);
                final key = dateKeyFromDateTime(date);
                final isDone = monthDone.contains(key);
                final isBeforeStart =
                    normalizedStartDate != null && date.isBefore(normalizedStartDate);
                final isPastNotDone =
                    !isBeforeStart &&
                    !isDone &&
                    key.compareTo(logicalDateKeyFromNow()) < 0;

                if (isBeforeStart) {
                  return Center(
                    child: Text(
                      '$day',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final bg = isDone
                    ? Colors.transparent
                    : Colors.transparent;
                final border = isDone
                    ? const Color(0xFF00C565)
                    : isPastNotDone
                    ? const Color(0xFFFF3366)
                    : const Color(0xFF2A2E38);
                final textColor = isDone
                    ? Colors.white
                    : Colors.white;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final side =
                        (constraints.biggest.shortestSide * 0.86).clamp(
                          26.0,
                          38.0,
                        );
                    return Center(
                      child: Container(
                        width: side,
                        height: side,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(side * 0.42),
                          border: Border.all(color: border, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: textColor,
                              fontSize: (side * 0.48).clamp(12.0, 18.0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 82,
      child: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          if (_applyingWeekChange || page == 1) return;
          _applyingWeekChange = true;
          widget.onWeekOffsetChange?.call(page == 2 ? 1 : -1);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pageController.hasClients) {
              _applyingWeekChange = false;
              return;
            }
            _pageController.jumpToPage(1);
            _applyingWeekChange = false;
          });
        },
        children: [
          _buildWeekRow(
            context: context,
            keys: _keysForOffset(widget.weekOffset - 1),
            done: done,
            normalizedStartDate: normalizedStartDate,
          ),
          _buildWeekRow(
            context: context,
            keys: _keysForOffset(widget.weekOffset),
            done: done,
            normalizedStartDate: normalizedStartDate,
          ),
          _buildWeekRow(
            context: context,
            keys: _keysForOffset(widget.weekOffset + 1),
            done: done,
            normalizedStartDate: normalizedStartDate,
          ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  final List<Completion> completions;
  final DateTime? startDate;
  final int weekOffset;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _CardFooter({
    required this.completions,
    this.startDate,
    this.weekOffset = 0,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final refNow = logicalDateFromDateTime(
      DateTime.now(),
    ).add(Duration(days: weekOffset * 7));
    final keys = dateKeysForLastNDays(7, now: refNow);
    final done = completions.map((c) => c.dateKey).toSet();
    final normalizedStartDate = startDate == null
        ? null
        : DateTime(startDate!.year, startDate!.month, startDate!.day);
    final validKeys = keys.where((key) {
      if (normalizedStartDate == null) return true;
      final date = dateFromDateKey(key);
      return !DateTime(date.year, date.month, date.day).isBefore(
        normalizedStartDate,
      );
    });
    final validCount = validKeys.length;
    final doneCount = validKeys.where(done.contains).length;
    final percent = validCount == 0 ? 0 : ((doneCount / validCount) * 100).round();
    final firstDate = dateFromDateKey(keys.first);
    final lastDate = dateFromDateKey(keys.last);
    final weekRangeLabel =
        '${firstDate.day}/${firstDate.month} - ${lastDate.day}/${lastDate.month}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final percentFontSize = compact ? 20.0 : 22.0;
          final metricFontSize = compact ? 14.0 : 15.0;
          final iconGap = compact ? 8.0 : 10.0;
          return Row(
            children: [
              const Icon(Icons.link, color: Color(0xFF4CA0FF), size: 16),
              const SizedBox(width: 4),
              Text(
                '$doneCount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: metricFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: iconGap),
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF4CA0FF),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '$percent%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: percentFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  weekRangeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: iconGap),
              GestureDetector(
                onTap: onToggleExpand,
                child: AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthWeekLabel extends StatelessWidget {
  final String text;
  final bool isWeekend;

  const _MonthWeekLabel(this.text, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isWeekend ? const Color(0xFFC63C54) : Colors.white60,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
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
    default:
      return 'Diciembre';
  }
}

String _weekdayShort(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Lun';
    case DateTime.tuesday:
      return 'Mar';
    case DateTime.wednesday:
      return 'Mié';
    case DateTime.thursday:
      return 'Jue';
    case DateTime.friday:
      return 'Vie';
    case DateTime.saturday:
      return 'Sáb';
    case DateTime.sunday:
      return 'Dom';
    default:
      return '';
  }
}
