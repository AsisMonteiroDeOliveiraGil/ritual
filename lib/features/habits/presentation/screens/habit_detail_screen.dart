import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';
import 'package:ritual/features/habits/presentation/screens/habit_manage_screen.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  final int initialTab;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late DateTime _visibleMonth;
  int _selectedTab = 0;
  Timer? _midnightTimer;
  late final PageController _tabPageController;
  late final PageController _monthPageController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedTab = widget.initialTab.clamp(0, 2);
    _tabPageController = PageController(initialPage: _selectedTab);
    _monthPageController = PageController(initialPage: 1);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _tabPageController.dispose();
    _monthPageController.dispose();
    super.dispose();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = nextLogicalDayBoundary(now);
    final wait = next.difference(now);
    _midnightTimer = Timer(wait, () {
      if (!mounted) return;
      setState(() {
        final nowDate = logicalDateFromDateTime(DateTime.now());
        _visibleMonth = DateTime(nowDate.year, nowDate.month);
      });
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _toggleDay(Habit habit, DateTime date, bool isDone) async {
    final key = dateKeyFromDateTime(date);
    if (isDone) {
      final unmark = await ref.read(unmarkHabitDoneProvider.future);
      await unmark(habit.id, key);
      return;
    }
    final mark = await ref.read(markHabitDoneProvider.future);
    await mark(habit.id, key, source: 'detail_calendar');
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFF0B0D11);

    final habits = ref.watch(watchActiveHabitsProvider);
    final stats = ref.watch(habitStatsProvider(widget.habitId));
    final monthCompletions = ref.watch(
      habitMonthCompletionsProvider((
        habitId: widget.habitId,
        month: _visibleMonth,
      )),
    );
    final prevMonthCompletions = ref.watch(
      habitMonthCompletionsProvider((
        habitId: widget.habitId,
        month: DateTime(_visibleMonth.year, _visibleMonth.month - 1),
      )),
    );
    final nextMonthCompletions = ref.watch(
      habitMonthCompletionsProvider((
        habitId: widget.habitId,
        month: DateTime(_visibleMonth.year, _visibleMonth.month + 1),
      )),
    );

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: habits.when(
          data: (items) {
            Habit? habit;
            for (final h in items) {
              if (h.id == widget.habitId) {
                habit = h;
                break;
              }
            }
            if (habit == null) {
              return const Center(
                child: Text(
                  'Hábito no encontrado',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            final activeHabit = habit;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: <Widget>[
                      _HeaderActionButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activeHabit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _HeaderActionButton(
                        icon: Icons.close,
                        onTap: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                _DetailTabs(
                  selectedIndex: _selectedTab,
                  onTap: (index) {
                    setState(() => _selectedTab = index);
                    _tabPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
                const Divider(height: 1, color: Color(0xFF1A1D24)),
                Expanded(
                  child: PageView(
                    controller: _tabPageController,
                    onPageChanged: (index) {
                      if (_selectedTab != index) {
                        setState(() => _selectedTab = index);
                      }
                    },
                    children: [
                      (monthCompletions.isLoading ||
                              prevMonthCompletions.isLoading ||
                              nextMonthCompletions.isLoading)
                          ? const Center(child: CircularProgressIndicator())
                          : (monthCompletions.hasError ||
                                prevMonthCompletions.hasError ||
                                nextMonthCompletions.hasError)
                          ? Center(
                              child: Text(
                                'Error: ${monthCompletions.error ?? prevMonthCompletions.error ?? nextMonthCompletions.error}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            )
                          : PageView(
                              controller: _monthPageController,
                              physics: const PageScrollPhysics(),
                              onPageChanged: (page) {
                                if (page == 1) return;
                                setState(() {
                                  _visibleMonth = DateTime(
                                    _visibleMonth.year,
                                    _visibleMonth.month + (page == 2 ? 1 : -1),
                                  );
                                });
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted &&
                                      _monthPageController.hasClients) {
                                    _monthPageController.jumpToPage(1);
                                  }
                                });
                              },
                              children: [
                                _DetailCalendarAndInfo(
                                  habit: activeHabit,
                                  visibleMonth: DateTime(
                                    _visibleMonth.year,
                                    _visibleMonth.month - 1,
                                  ),
                                  doneKeys:
                                      (prevMonthCompletions.asData?.value ??
                                              const [])
                                          .map((e) => e.dateKey)
                                          .toSet(),
                                  statsDays:
                                      stats.asData?.value.currentStreak ?? 0,
                                  onPrevMonth: () {
                                    _monthPageController.animateToPage(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  onNextMonth: () {
                                    _monthPageController.animateToPage(
                                      2,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  onToggleDate: (date, isDone) =>
                                      _toggleDay(activeHabit, date, isDone),
                                ),
                                _DetailCalendarAndInfo(
                                  habit: activeHabit,
                                  visibleMonth: _visibleMonth,
                                  doneKeys:
                                      (monthCompletions.asData?.value ??
                                              const [])
                                          .map((e) => e.dateKey)
                                          .toSet(),
                                  statsDays:
                                      stats.asData?.value.currentStreak ?? 0,
                                  onPrevMonth: () {
                                    _monthPageController.animateToPage(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  onNextMonth: () {
                                    _monthPageController.animateToPage(
                                      2,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  onToggleDate: (date, isDone) =>
                                      _toggleDay(activeHabit, date, isDone),
                                ),
                                _DetailCalendarAndInfo(
                                  habit: activeHabit,
                                  visibleMonth: DateTime(
                                    _visibleMonth.year,
                                    _visibleMonth.month + 1,
                                  ),
                                  doneKeys:
                                      (nextMonthCompletions.asData?.value ??
                                              const [])
                                          .map((e) => e.dateKey)
                                          .toSet(),
                                  statsDays:
                                      stats.asData?.value.currentStreak ?? 0,
                                  onPrevMonth: () {
                                    _monthPageController.animateToPage(
                                      0,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  onNextMonth: () {
                                    _monthPageController.animateToPage(
                                      2,
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  onToggleDate: (date, isDone) =>
                                      _toggleDay(activeHabit, date, isDone),
                                ),
                              ],
                            ),
                      _DetailStatisticsTab(
                        habitId: widget.habitId,
                        visibleMonth: _visibleMonth,
                        stats: stats.asData?.value,
                        habitStartDate: activeHabit.startDate,
                      ),
                      HabitEditTab(habit: activeHabit),
                    ],
                  ),
                ),
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

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1F28),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: const Color(0xFFC63C54), size: 20),
        ),
      ),
    );
  }
}

class _DetailTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DetailTabs({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF12161D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF232833)),
        ),
        child: Row(
          children: [
            _Tab(
              label: 'Calendario',
              active: selectedIndex == 0,
              onTap: () => onTap(0),
            ),
            _Tab(
              label: 'Estadísticas',
              active: selectedIndex == 1,
              onTap: () => onTap(1),
            ),
            _Tab(
              label: 'Editar',
              active: selectedIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC63C54) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFC63C54).withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 15,
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

class _DetailStatisticsTab extends ConsumerWidget {
  final String habitId;
  final DateTime visibleMonth;
  final dynamic stats;
  final DateTime? habitStartDate;

  const _DetailStatisticsTab({
    required this.habitId,
    required this.visibleMonth,
    required this.stats,
    required this.habitStartDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = logicalDateFromDateTime(DateTime.now());
    final todayKey = dateKeyFromDateTime(now);
    final normalizedStartDate = habitStartDate == null
        ? null
        : DateTime(
            habitStartDate!.year,
            habitStartDate!.month,
            habitStartDate!.day,
          );
    final startKey = normalizedStartDate == null
        ? null
        : dateKeyFromDateTime(normalizedStartDate);
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final monthEnd = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);
    final yearStart = DateTime(visibleMonth.year, 1, 1);
    final yearEnd = DateTime(visibleMonth.year, 12, 31);

    final monthCompletions = ref.watch(
      habitCompletionsRangeProvider((
        habitId: habitId,
        fromDateKey: dateKeyFromDateTime(monthStart),
        toDateKey: dateKeyFromDateTime(monthEnd),
      )),
    );
    final yearCompletions = ref.watch(
      habitCompletionsRangeProvider((
        habitId: habitId,
        fromDateKey: dateKeyFromDateTime(yearStart),
        toDateKey: dateKeyFromDateTime(yearEnd),
      )),
    );
    final lifetimeCompletions = ref.watch(
      habitCompletionsRangeProvider((
        habitId: habitId,
        fromDateKey: '2000-01-01',
        toDateKey: todayKey,
      )),
    );

    if (monthCompletions.isLoading ||
        yearCompletions.isLoading ||
        lifetimeCompletions.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (monthCompletions.hasError ||
        yearCompletions.hasError ||
        lifetimeCompletions.hasError) {
      return const Center(
        child: Text(
          'No se pudieron cargar estadísticas',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    bool onOrAfterStart(String key) =>
        startKey == null || key.compareTo(startKey) >= 0;

    final monthDoneKeys = {
      for (final c in monthCompletions.value ?? const [])
        if (onOrAfterStart(c.dateKey)) c.dateKey,
    };
    final yearDoneKeys = {
      for (final c in yearCompletions.value ?? const [])
        if (onOrAfterStart(c.dateKey)) c.dateKey,
    };
    final lifetimeDoneKeys = {
      for (final c in lifetimeCompletions.value ?? const [])
        if (onOrAfterStart(c.dateKey)) c.dateKey,
    };
    final lifetimeDone = lifetimeDoneKeys.length;

    final isCurrentMonth =
        visibleMonth.year == now.year && visibleMonth.month == now.month;
    final effectiveMonthStart = normalizedStartDate != null &&
            normalizedStartDate.isAfter(monthStart)
        ? normalizedStartDate
        : monthStart;
    final effectiveMonthTrackingEnd = isCurrentMonth
        ? DateTime(now.year, now.month, now.day)
        : monthEnd;
    final hasMonthWindow = !effectiveMonthStart.isAfter(monthEnd);
    final trackedDaysInMonth = !hasMonthWindow ||
            effectiveMonthTrackingEnd.isBefore(effectiveMonthStart)
        ? 0
        : effectiveMonthTrackingEnd.difference(effectiveMonthStart).inDays + 1;
    final doneInMonth = monthDoneKeys.where((key) {
      if (!hasMonthWindow) return false;
      final d = dateFromDateKey(key);
      return !d.isBefore(effectiveMonthStart) &&
          !d.isAfter(effectiveMonthTrackingEnd);
    }).length;
    final failInMonth = math.max(0, trackedDaysInMonth - doneInMonth);

    final score = ((stats?.percent30 ?? 0.0) * 100).round().clamp(0, 100);
    final progressTotal = !hasMonthWindow
        ? 0
        : monthEnd.difference(effectiveMonthStart).inDays + 1;
    final progressValue = progressTotal == 0 ? 0 : doneInMonth / progressTotal;

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekFromKey = dateKeyFromDateTime(
      DateTime(weekStart.year, weekStart.month, weekStart.day),
    );
    final weekDone = (lifetimeCompletions.value ?? const [])
        .where(
          (c) =>
              c.dateKey.compareTo(weekFromKey) >= 0 &&
              c.dateKey.compareTo(todayKey) <= 0 &&
              onOrAfterStart(c.dateKey),
        )
        .length;
    final yearDone = yearDoneKeys
        .where((k) => k.compareTo(todayKey) <= 0)
        .length;
    final monthDone = monthDoneKeys
        .where((k) => k.compareTo(todayKey) <= 0)
        .length;

    final monthSeriesStart = DateTime(visibleMonth.year, visibleMonth.month, 8);
    final monthSeries = List<DateTime>.generate(
      15,
      (i) => monthSeriesStart.add(Duration(days: i)),
    );

    final perMonthDone = List<int>.generate(12, (index) {
      final m = index + 1;
      final from = dateKeyFromDateTime(DateTime(visibleMonth.year, m, 1));
      final to = dateKeyFromDateTime(DateTime(visibleMonth.year, m + 1, 0));
      return yearDoneKeys
          .where((k) => k.compareTo(from) >= 0 && k.compareTo(to) <= 0)
          .length;
    });
    final maxBar = perMonthDone.fold<int>(1, (p, v) => v > p ? v : p);
    final last14Days = List<DateTime>.generate(
      14,
      (i) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 13 - i)),
    );
    final last14Series = last14Days
        .map(
          (d) => lifetimeDoneKeys.contains(dateKeyFromDateTime(d)) ? 1.0 : 0.0,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        _StatsSectionCard(
          icon: Icons.emoji_events_outlined,
          label: 'Puntuación del hábito',
          child: Column(
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 10,
                      color: const Color(0xFF1E2128),
                      backgroundColor: Colors.transparent,
                    ),
                    CircularProgressIndicator(
                      value: (score / 100).clamp(0.0, 1.0),
                      strokeWidth: 10,
                      color: const Color(0xFFC63C54),
                      backgroundColor: Colors.transparent,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.outlined_flag,
          label: 'Progreso del hábito',
          child: Column(
            children: [
              Text(
                '$doneInMonth/$progressTotal DÍAS',
                style: const TextStyle(
                  color: Color(0xFFC63C54),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progressValue.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: const Color(0xFF1E2128),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFC63C54),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${effectiveMonthStart.day}/${effectiveMonthStart.month}/${effectiveMonthStart.year % 100}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const Spacer(),
                  Text(
                    '${monthEnd.day}/${monthEnd.month}/${monthEnd.year % 100}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.link,
          label: 'Racha',
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Actual',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats?.currentStreak ?? 0} DÍAS',
                      style: const TextStyle(
                        color: Color(0xFFC63C54),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 64, color: const Color(0xFF1E2128)),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Mejor',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats?.maxStreak ?? 0} DÍAS',
                      style: const TextStyle(
                        color: Color(0xFFC63C54),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.timeline,
          label: 'Tendencia (14 días)',
          child: Column(
            children: [
              SizedBox(
                height: 84,
                child: CustomPaint(
                  size: const Size(double.infinity, 84),
                  painter: _MiniTrendPainter(values: last14Series),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${last14Days.first.day}/${last14Days.first.month}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    '${last14Days.last.day}/${last14Days.last.month}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.check_circle_outline,
          label: 'Veces completado',
          child: Column(
            children: [
              _StatRow(label: 'Esta semana', value: weekDone),
              _StatRow(label: 'Este mes', value: monthDone),
              _StatRow(label: 'Este año', value: yearDone),
              _StatRow(label: 'Total', value: lifetimeDone),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.show_chart,
          label: '${_monthName(visibleMonth.month)} ${visibleMonth.year}',
          child: Column(
            children: [
              SizedBox(
                height: 46,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthSeries.map((date) {
                    final key = dateKeyFromDateTime(date);
                    final isFuture = date.isAfter(now);
                    final isBeforeStart =
                        normalizedStartDate != null &&
                        date.isBefore(normalizedStartDate);
                    final done = monthDoneKeys.contains(key);
                    final color = isBeforeStart
                        ? const Color(0xFF454A55)
                        : isFuture
                        ? const Color(0xFF525761)
                        : done
                        ? const Color(0xFF00C565)
                        : const Color(0xFFFF3366);
                    final icon = isBeforeStart
                        ? Icons.remove
                        : done
                        ? Icons.check
                        : (isFuture ? Icons.remove : Icons.close);
                    return Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 20,
                          height: done || !isFuture ? 28 : 6,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(icon, color: color, size: 14),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: monthSeries
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            '${d.day}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.bar_chart,
          label: '${visibleMonth.year} veces completado',
          child: Column(
            children: [
              SizedBox(
                height: 148,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (index) {
                    final value = perMonthDone[index];
                    final h = value == 0 ? 2.0 : (value / maxBar) * 96 + 8;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (value > 0)
                            Text(
                              '$value',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            width: 14,
                            height: h,
                            decoration: BoxDecoration(
                              color: value > 0
                                  ? const Color(0xFFC63C54)
                                  : const Color(0xFF2A2F38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _monthName(index + 1).substring(0, 3),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.pie_chart_outline,
          label: 'Éxito / Fallo',
          child: Row(
            children: [
              SizedBox(
                width: 144,
                height: 144,
                child: CustomPaint(
                  painter: _DonutPainter(
                    done: doneInMonth,
                    fail: failInMonth,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendDot(
                      color: const Color(0xFF00C565),
                      text: 'Hecho $doneInMonth',
                    ),
                    const SizedBox(height: 8),
                    _LegendDot(
                      color: const Color(0xFFFF3366),
                      text: 'Fallo $failInMonth',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.workspace_premium_outlined,
          label: 'Medallas de racha',
          child: _MilestoneBadges(
            currentValue: stats?.maxStreak ?? 0,
            steps: const [3, 7, 14, 30, 60, 100, 200],
            suffix: 'd',
          ),
        ),
        const SizedBox(height: 10),
        _StatsSectionCard(
          icon: Icons.emoji_events_outlined,
          label: 'Medallas por días completados',
          child: _MilestoneBadges(
            currentValue: lifetimeDone,
            steps: const [5, 10, 25, 50, 100, 250, 500],
            suffix: '',
          ),
        ),
      ],
    );
  }
}

class _DetailCalendarAndInfo extends StatelessWidget {
  final Habit habit;
  final DateTime visibleMonth;
  final Set<String> doneKeys;
  final int statsDays;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function(DateTime date, bool isDone) onToggleDate;

  const _DetailCalendarAndInfo({
    required this.habit,
    required this.visibleMonth,
    required this.doneKeys,
    required this.statsDays,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToggleDate,
  });

  @override
  Widget build(BuildContext context) {
    final monthTitle = _monthName(visibleMonth.month);
    final monthGrid = _buildMonthGrid(visibleMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPrevMonth,
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
                        monthTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
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
                  onPressed: onNextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFC63C54),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _WeekdayHeader(),
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
                if (!inMonth) {
                  return const SizedBox.shrink();
                }
                final dayDate = DateTime(date.year, date.month, date.day);
                final startDate = habit.startDate == null
                    ? null
                    : DateTime(
                        habit.startDate!.year,
                        habit.startDate!.month,
                        habit.startDate!.day,
                      );
                final beforeStart = startDate != null && dayDate.isBefore(startDate);
                final isDone = !beforeStart && doneKeys.contains(dateKey);
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
                    if (isFuture || beforeStart) return;
                    await onToggleDate(date, isDone);
                  },
                  child: _DayCell(
                    day: date.day,
                    inMonth: inMonth,
                    isDone: isDone,
                    isToday: isToday,
                    isFuture: isFuture,
                    isInactive: beforeStart,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        _InfoCard(
          icon: Icons.link,
          iconColor: const Color(0xFFC63C54),
          label: 'Racha',
          content: '$statsDays DÍAS',
          contentColor: const Color(0xFFC63C54),
        ),
        const SizedBox(height: 10),
        _InfoCard(
          icon: Icons.info_outline,
          iconColor: const Color(0xFFC63C54),
          label: 'Descripción',
          content: (habit.description?.trim().isNotEmpty ?? false)
              ? habit.description!.trim()
              : 'Sin descripción',
        ),
        const SizedBox(height: 10),
        const _InfoCard(
          icon: Icons.chat_bubble_outline,
          iconColor: Color(0xFFC63C54),
          label: 'Notas',
          content: 'Sin notas para este mes',
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

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

class _DayCell extends StatelessWidget {
  final int day;
  final bool inMonth;
  final bool isDone;
  final bool isToday;
  final bool isFuture;
  final bool isInactive;

  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isDone,
    required this.isToday,
    required this.isFuture,
    this.isInactive = false,
  });

  @override
  Widget build(BuildContext context) {
    const doneColor = Color(0xFF00C565);
    const notDoneColor = Color(0xFFFF3366);

    Color border = Colors.transparent;
    if (inMonth) {
      if (isInactive) {
        border = Colors.transparent;
      } else if (isDone) {
        border = doneColor;
      } else if (isFuture) {
        border = const Color(0xFF2A2E38);
      } else {
        border = notDoneColor;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.biggest.shortestSide * 0.86).clamp(26.0, 38.0);
        return Center(
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(side * 0.42),
              border: Border.all(color: border, width: 2),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: !inMonth
                      ? Colors.white24
                      : isInactive
                      ? Colors.white24
                      : isDone
                      ? Colors.white
                      : Colors.white,
                  fontSize: (side * 0.48).clamp(12.0, 18.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String content;
  final Color contentColor;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.content,
    this.contentColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF202633)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10141C), Color(0xFF0D1017)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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

class _StatsSectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _StatsSectionCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF202633)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10141C), Color(0xFF0D1017)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFC63C54), size: 18),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F26),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 18),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2128))),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendDot({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}

class _MilestoneBadges extends StatelessWidget {
  final int currentValue;
  final List<int> steps;
  final String suffix;

  const _MilestoneBadges({
    required this.currentValue,
    required this.steps,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final step = steps[index];
          final unlocked = currentValue >= step;
          return _MilestoneBadge(
            unlocked: unlocked,
            label: suffix.isEmpty ? '$step' : '$step$suffix',
            isFirst: index == 0,
          );
        },
      ),
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  final bool unlocked;
  final String label;
  final bool isFirst;

  const _MilestoneBadge({
    required this.unlocked,
    required this.label,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = unlocked ? const Color(0xFF1E2A4A) : const Color(0xFF1A1D24);
    final border = unlocked ? const Color(0xFF2F62D6) : const Color(0xFF2B303A);
    final iconBg = unlocked ? const Color(0xFF2F62D6) : const Color(0xFF30343C);

    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  unlocked
                      ? (isFirst ? Icons.star_rounded : Icons.workspace_premium)
                      : Icons.lock_outline_rounded,
                  color: unlocked ? Colors.white : Colors.white54,
                  size: unlocked ? 24 : 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? Colors.white : Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int done;
  final int fail;

  const _DonutPainter({
    required this.done,
    required this.fail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = (done + fail).toDouble();
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const stroke = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;

    void arc(double value, Color color) {
      if (value <= 0) return;
      final sweep = (value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    arc(done.toDouble(), const Color(0xFF00C565));
    arc(fail.toDouble(), const Color(0xFFFF3366));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return done != oldDelegate.done || fail != oldDelegate.fail;
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<double> values;

  const _MiniTrendPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final left = 6.0;
    final right = size.width - 6.0;
    final top = 8.0;
    final bottom = size.height - 10.0;
    final width = right - left;
    final height = bottom - top;
    final step = values.length > 1 ? width / (values.length - 1) : 0.0;

    final gridPaint = Paint()
      ..color = const Color(0xFF222630)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), gridPaint);
    canvas.drawLine(
      Offset(left, top + (height / 2)),
      Offset(right, top + (height / 2)),
      gridPaint,
    );

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = left + (step * i);
      final y = bottom - (values[i].clamp(0, 1) * height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFFC63C54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = const Color(0xFFFFB400);
    for (var i = 0; i < values.length; i++) {
      final x = left + (step * i);
      final y = bottom - (values[i].clamp(0, 1) * height);
      canvas.drawCircle(Offset(x, y), 2.2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    if (values.length != oldDelegate.values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (values[i] != oldDelegate.values[i]) return true;
    }
    return false;
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
