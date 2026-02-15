import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/core/ui/icon_mapper.dart';
import 'package:ritual/day_chip.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';
import 'package:ritual/features/habits/presentation/providers/today_selected_date_provider.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  DateTime? _prevSelectedDate;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(todaySelectedDateProvider);
    final dateKey = dateKeyFromDateTime(selectedDate);
    final habits = ref.watch(watchActiveHabitsProvider);
    final completions = ref.watch(completionsForDateProvider(dateKey));
    final days = _buildDays(selectedDate);
    final previous = _prevSelectedDate;
    final isForward = previous == null
        ? true
        : DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            ).isAfter(
              DateTime(
                previous.year,
                previous.month,
                previous.day,
              ),
            );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prevSelectedDate = selectedDate;
    });

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'Hoy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC63C54),
        onPressed: () => context.push('/habit/new'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 12.0;
                const gap = 4.0;
                final totalGap = gap * 6;
                final available =
                    constraints.maxWidth - (horizontalPadding * 2) - totalGap;
                final itemWidth = available / 7;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final begin = Offset(isForward ? 0.15 : -0.15, 0);
                        final tween = Tween<Offset>(
                          begin: begin,
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                      },
                      child: Row(
                        key: ValueKey(dateKey),
                        children: [
                          for (var i = 0; i < days.length; i++) ...[
                            if (i > 0) const SizedBox(width: gap),
                            DayChip(
                              dayLabel: days[i].label,
                              dayNumber: days[i].number,
                              isSelected:
                                  _isSameDay(days[i].date, selectedDate),
                              isToday: _isSameDay(days[i].date, DateTime.now()),
                              width: itemWidth,
                              onTap: () => ref
                                  .read(todaySelectedDateProvider.notifier)
                                  .state = days[i].date,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: habits.when(
              data: (items) => completions.when(
                data: (map) => _HabitList(
                  habits: items
                      .where(
                        (habit) => _isHabitVisibleForDate(habit, selectedDate),
                      )
                      .toList(),
                  completions: map,
                  onToggle: (habit, isDone) async {
                    if (isDone) {
                      final unmark =
                          await ref.read(unmarkHabitDoneProvider.future);
                      await unmark(habit.id, dateKey);
                      return;
                    }
                    final usecase =
                        await ref.read(markHabitDoneProvider.future);
                    await usecase(habit.id, dateKey, source: 'app');
                    final stats =
                        await ref.read(habitStatsProvider(habit.id).future);
                    final isRecord = stats.currentStreak == stats.maxStreak;
                    final shouldConfetti = isRecord &&
                        (stats.currentStreak == 1 ||
                            stats.currentStreak == 7);
                    if (context.mounted) {
                      await _showWellDoneDialog(
                        context,
                        habit.name,
                        showConfetti: shouldConfetti,
                      );
                    }
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitList extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, Completion> completions;
  final Future<void> Function(Habit habit, bool isDone) onToggle;

  const _HabitList({
    required this.habits,
    required this.completions,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No hay hábitos activos.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    final sorted = [...habits]
      ..sort((a, b) {
        final aDone = completions.containsKey(a.id);
        final bDone = completions.containsKey(b.id);
        if (aDone == bDone) {
          return a.order.compareTo(b.order);
        }
        return aDone ? 1 : -1; // done goes to bottom
      });

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        96 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final habit = sorted[index];
        final isDone = completions.containsKey(habit.id);
        return _HabitRow(
          habit: habit,
          isDone: isDone,
          onToggle: () {
            onToggle(habit, isDone);
          },
          onLongPress: () => context.push('/habit/${habit.id}/manage'),
        );
      },
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const _HabitRow({
    required this.habit,
    required this.isDone,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    const bg = Color(0xFF111111);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconFromName(habit.icon),
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TicketBadge(
                    text: 'Hábito',
                    background: Colors.white10,
                    border: Colors.white24,
                    holeColor: bg,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DoneIndicator(isDone: isDone),
          ],
        ),
      ),
    );
  }
}

class _DoneIndicator extends StatelessWidget {
  final bool isDone;

  const _DoneIndicator({required this.isDone});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC63C54);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? accent : Colors.transparent,
        border: Border.all(
          color: isDone ? accent : Colors.white24,
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: isDone
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _TicketBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color border;
  final Color holeColor;

  const _TicketBadge({
    required this.text,
    required this.background,
    required this.border,
    required this.holeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Positioned(
          left: -4,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: holeColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayItem {
  final DateTime date;
  final String label;
  final String number;

  const _DayItem(this.date, this.label, this.number);
}

List<_DayItem> _buildDays(DateTime selectedDate) {
  final base = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );
  final days = <_DayItem>[];
  for (var i = -3; i <= 3; i++) {
    final date = base.add(Duration(days: i));
    days.add(_DayItem(date, _weekdayLabel(date.weekday), '${date.day}'));
  }
  return days;
}

String _weekdayLabel(int weekday) {
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

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isHabitVisibleForDate(Habit habit, DateTime selectedDate) {
  final start = habit.startDate;
  final end = habit.endDate;
  final day = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  if (start != null) {
    final s = DateTime(start.year, start.month, start.day);
    if (day.isBefore(s)) return false;
  }
  if (end != null) {
    final e = DateTime(end.year, end.month, end.day);
    if (day.isAfter(e)) return false;
  }
  return true;
}

Future<void> _showWellDoneDialog(
  BuildContext context,
  String habitName, {
  bool showConfetti = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) {
      return _WellDoneDialog(
        habitName: habitName,
        showConfetti: showConfetti,
      );
    },
  );
}

class _WellDoneDialog extends StatefulWidget {
  final String habitName;
  final bool showConfetti;

  const _WellDoneDialog({
    required this.habitName,
    required this.showConfetti,
  });

  @override
  State<_WellDoneDialog> createState() => _WellDoneDialogState();
}

class _WellDoneDialogState extends State<_WellDoneDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    if (widget.showConfetti) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡Bien hecho!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1218),
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFC63C54),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.habitName,
                  style: const TextStyle(
                    color: Color(0xFFC63C54),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nueva mejor racha\n1 día',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 10),
                const Text(
                  'Próximo logro: 7 días',
                  style: TextStyle(color: Colors.white38),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 10),
                const Text(
                  'COMPARTIR',
                  style: TextStyle(
                    color: Color(0xFFC63C54),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CERRAR',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showConfetti)
            Positioned(
              top: 0,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.02,
                numberOfParticles: 18,
                maxBlastForce: 12,
                minBlastForce: 6,
                gravity: 0.3,
                colors: const [
                  Color(0xFFC63C54),
                  Color(0xFF6AE0FF),
                  Color(0xFFF4B23C),
                  Color(0xFF7FC34A),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
