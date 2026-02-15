import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ritual/core/time/date_key.dart';
import 'package:ritual/day_chip.dart';
import 'package:ritual/features/habits/domain/entities/completion.dart';
import 'package:ritual/features/habits/domain/entities/habit.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';
import 'package:ritual/features/habits/presentation/providers/today_selected_date_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Timer? _dayBoundaryTimer;
  DateTime? _scheduledLogicalDate;

  @override
  void initState() {
    super.initState();
    _scheduleDayBoundaryRefresh();
  }

  @override
  void dispose() {
    _dayBoundaryTimer?.cancel();
    super.dispose();
  }

  void _scheduleDayBoundaryRefresh() {
    _dayBoundaryTimer?.cancel();
    final now = DateTime.now();
    _scheduledLogicalDate = logicalDateFromDateTime(now);
    final nextBoundary = nextLogicalDayBoundary(now);
    _dayBoundaryTimer = Timer(nextBoundary.difference(now), () {
      if (!mounted) return;
      final selectedDate = ref.read(todaySelectedDateProvider);
      final previousLogical = _scheduledLogicalDate;
      final currentLogical = logicalDateFromDateTime(DateTime.now());
      if (previousLogical != null && _isSameDay(selectedDate, previousLogical)) {
        ref.read(todaySelectedDateProvider.notifier).state = DateTime(
          currentLogical.year,
          currentLogical.month,
          currentLogical.day,
        );
      }
      setState(() {});
      _scheduleDayBoundaryRefresh();
    });
  }

  Future<void> _onRefresh(String dateKey) async {
    ref.invalidate(habitsRepositoryProvider);
    ref.invalidate(watchActiveHabitsProvider);
    ref.invalidate(completionsForDateProvider(dateKey));
    await Future.wait([
      ref.read(watchActiveHabitsProvider.future),
      ref.read(completionsForDateProvider(dateKey).future),
    ]);
  }

  void _showShakeDetectedSnack(bool isRainMode) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isRainMode
                ? 'Shake detectado: cambiando a lluvia'
                : 'Shake detectado: cambiando a nieve',
          ),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(todaySelectedDateProvider);
    final logicalToday = logicalDateFromDateTime(DateTime.now());
    final selectedTitle = _isSameDay(selectedDate, logicalToday)
        ? 'Hoy'
        : '${_weekdayLabel(selectedDate.weekday)} ${selectedDate.day} ${_monthLabelShort(selectedDate.month)}';
    final dateKey = dateKeyFromDateTime(selectedDate);
    final habits = ref.watch(watchActiveHabitsProvider);
    final completions = ref.watch(completionsForDateProvider(dateKey));
    final days = _buildDays(selectedDate);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF111111),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111111),
            elevation: 0,
            title: Text(
              selectedTitle,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Nuevo hábito',
                onPressed: () => context.push('/habit/new'),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
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
                        constraints.maxWidth -
                        (horizontalPadding * 2) -
                        totalGap;
                    final itemWidth = available / 7;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
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
                                  isSelected: _isSameDay(
                                    days[i].date,
                                    selectedDate,
                                  ),
                                  isToday: _isSameDay(
                                    days[i].date,
                                    logicalDateFromDateTime(DateTime.now()),
                                  ),
                                  width: itemWidth,
                                  onTap: () =>
                                      ref
                                          .read(
                                            todaySelectedDateProvider.notifier,
                                          )
                                          .state = days[i]
                                          .date,
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
                child: RefreshIndicator.adaptive(
                  onRefresh: () => _onRefresh(dateKey),
                  child: habits.when(
                    data: (items) => completions.when(
                      data: (map) => _HabitList(
                        habits: items
                            .where(
                              (habit) =>
                                  _isHabitVisibleForDate(habit, selectedDate),
                            )
                            .toList(),
                        completions: map,
                        onToggle: (habit, isDone) async {
                          if (isDone) {
                            final unmark = await ref.read(
                              unmarkHabitDoneProvider.future,
                            );
                            await unmark(habit.id, dateKey);
                            return;
                          }
                          final usecase = await ref.read(
                            markHabitDoneProvider.future,
                          );
                          await usecase(habit.id, dateKey, source: 'app');
                          final stats = await ref.read(
                            habitStatsProvider(habit.id).future,
                          );
                          final isRecord =
                              stats.currentStreak == stats.maxStreak;
                          const milestoneStreaks = <int>[7, 14, 30, 60, 100, 200];
                          final streak = stats.currentStreak;
                          final reachedMilestone =
                              isRecord && milestoneStreaks.contains(streak);
                          final nextMilestone = milestoneStreaks.firstWhere(
                            (m) => m > streak,
                            orElse: () => 0,
                          );
                          final shouldConfetti = reachedMilestone && streak >= 30;
                          if (context.mounted && reachedMilestone) {
                            await _showWellDoneDialog(
                              context,
                              habit.name,
                              streakDays: streak,
                              nextMilestoneDays: nextMilestone,
                              showConfetti: shouldConfetti,
                            );
                          }
                        },
                      ),
                      loading: () => const _PullPlaceholder(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => _PullPlaceholder(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    loading: () => const _PullPlaceholder(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => _PullPlaceholder(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // La nieve va en la capa superior de toda la screen (incluye AppBar).
        Positioned.fill(
          child: IgnorePointer(
            child: _SnowOverlay(onStrongShake: _showShakeDetectedSnack),
          ),
        ),
      ],
    );
  }
}

class _SnowOverlay extends StatefulWidget {
  final ValueChanged<bool>? onStrongShake;

  const _SnowOverlay({this.onStrongShake});

  @override
  State<_SnowOverlay> createState() => _SnowOverlayState();
}

class _SnowOverlayState extends State<_SnowOverlay>
    with SingleTickerProviderStateMixin {
  static const double _progressPerCycle = 37.5; // 300s / 8s
  late final AnimationController _controller;
  late final List<_SnowFlake> _flakes;
  final Stopwatch _clock = Stopwatch()..start();
  final List<_SnowGust> _gusts = <_SnowGust>[];
  final List<_SettledSnow> _settledSnow = <_SettledSnow>[];
  final List<_SettledRain> _settledRain = <_SettledRain>[];
  final math.Random _random = math.Random(42);
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  double _timeOffset = 0;
  double _fallProgress = 0;
  double _rainBlend = 0;
  double _targetRainBlend = 0;
  double _gravityX = 0;
  double _gravityY = 0;
  double _gravityZ = 0;
  int _lastShakeSnackMs = 0;
  bool _shakeArmed = true;
  int? _calmSinceMs;
  int _lastFrameMs = 0;
  Offset? _lastPointer;
  int _lastEmitMs = 0;

  @override
  void initState() {
    super.initState();
    _flakes = List.generate(90, (_) => _spawnFlake(initial: true));
    _controller =
        AnimationController(vsync: this, duration: const Duration(minutes: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _timeOffset += _progressPerCycle;
            }
          })
          ..repeat();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalPointer);
    _startShakeDetection();
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointer,
    );
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final nowMs = _clock.elapsedMilliseconds;
              _gusts.removeWhere((gust) => nowMs - gust.bornMs > 900);
              _updateWeatherBlend(nowMs);
              if (_lastFrameMs == 0) {
                _lastFrameMs = nowMs;
              }
              final dtMs = (nowMs - _lastFrameMs).clamp(0, 48);
              _lastFrameMs = nowMs;
              final dtSec = dtMs / 1000.0;
              final transitionKick = (_rainBlend * (1 - _rainBlend)) * 1.2;
              final speedBoost = 1.05 + (_rainBlend * 1.05) + transitionKick;
              _fallProgress += dtSec * speedBoost * 0.16;
              _stepParticles(nowMs, dtSec);
              return CustomPaint(
                painter: _SnowPainter(
                  driftProgress:
                      _timeOffset + (_controller.value * _progressPerCycle),
                  fallProgress: _fallProgress,
                  flakes: _flakes,
                  settledSnow: _settledSnow,
                  settledRain: _settledRain,
                  gusts: _gusts,
                  nowMs: nowMs,
                  opacity: 0.72,
                  rainBlend: _rainBlend,
                  sizeHint: size,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _startShakeDetection() {
    if (kIsWeb) return;
    try {
      _accelerometerSub = accelerometerEventStream().listen(
        (event) {
          final nowMs = _clock.elapsedMilliseconds;
          // Shake en cualquier eje: filtramos gravedad por componente y usamos
          // la magnitud dinamica total.
          const alpha = 0.9;
          _gravityX = (_gravityX * alpha) + (event.x * (1 - alpha));
          _gravityY = (_gravityY * alpha) + (event.y * (1 - alpha));
          _gravityZ = (_gravityZ * alpha) + (event.z * (1 - alpha));
          final dx = event.x - _gravityX;
          final dy = event.y - _gravityY;
          final dz = event.z - _gravityZ;
          final jerk = math.sqrt((dx * dx) + (dy * dy) + (dz * dz));
          final normalized = ((jerk - 4.0) / 6.8).clamp(0.0, 1.0);
          const triggerThreshold = 0.62;
          const calmThreshold = 0.18;
          const calmDurationMs = 320;

          if (normalized > triggerThreshold) {
            _calmSinceMs = null;
            if (_shakeArmed && nowMs - _lastShakeSnackMs >= 2000 && mounted) {
              _shakeArmed = false;
              _lastShakeSnackMs = nowMs;
              _targetRainBlend = _targetRainBlend > 0.5 ? 0.0 : 1.0;
              widget.onStrongShake?.call(_targetRainBlend > 0.5);
            }
          } else if (normalized < calmThreshold) {
            _calmSinceMs ??= nowMs;
            if (!_shakeArmed && nowMs - _calmSinceMs! >= calmDurationMs) {
              _shakeArmed = true;
            }
          } else {
            _calmSinceMs = null;
          }
        },
        onError: (error, stackTrace) {
          if (error is MissingPluginException) {
            _accelerometerSub?.cancel();
            _accelerometerSub = null;
            return;
          }
        },
        cancelOnError: false,
      );
    } on MissingPluginException {
      _accelerometerSub = null;
    }
  }

  void _updateWeatherBlend(int nowMs) {
    _rainBlend += (_targetRainBlend - _rainBlend) * 0.12;
    if ((_targetRainBlend - _rainBlend).abs() < 0.001) {
      _rainBlend = _targetRainBlend;
    }
  }

  _SnowFlake _spawnFlake({bool initial = false}) {
    return _SnowFlake(
      x: _random.nextDouble(),
      y: initial ? _random.nextDouble() : (-0.06 - _random.nextDouble() * 0.3),
      radius: 0.8 + _random.nextDouble() * 2.0,
      speed: 0.22 + _random.nextDouble() * 0.55,
      drift: (_random.nextDouble() - 0.5) * 0.12,
      kind: _random.nextInt(3),
      toneSeed: _random.nextDouble(),
      heightSeed: _random.nextDouble(),
    );
  }

  void _stepParticles(int nowMs, double dtSec) {
    // Acumulado desactivado: las partículas no se quedan en el suelo.
    final groundNorm = 1.0;

    for (var i = 0; i < _flakes.length; i++) {
      final flake = _flakes[i];
      flake.y += dtSec * flake.speed * 0.24;
      flake.x =
          (flake.x +
              math.sin(((_timeOffset + _fallProgress) + flake.y) * 8) *
                  flake.drift *
                  dtSec *
                  1.2) %
          1.0;
      if (flake.x < 0) flake.x += 1.0;

      for (final gust in _gusts) {
        final age = (nowMs - gust.bornMs) / 900.0;
        if (age <= 0 || age >= 1) continue;
        final dx = flake.x - gust.x;
        final dy = flake.y - gust.y;
        final dist2 = dx * dx + dy * dy;
        if (dist2 > 0.05) continue;
        final dist = math.sqrt(dist2 + 1e-6);
        final attenuation = (1 - age) * math.exp(-dist2 * 80);
        final push = 0.014 * attenuation;
        flake.x += (dx / dist) * push + gust.vx * 0.08 * attenuation;
        flake.y += (dy / dist) * push + gust.vy * 0.18 * attenuation;
      }

      if (flake.y >= groundNorm) {
        // Acumulado desactivado (comentado a propósito):
        // if (isRainMode) {
        //   _settledRain.add(...);
        // } else {
        //   _settledSnow.add(...);
        // }
        _flakes[i] = _spawnFlake();
      }
    }

    // Limpieza defensiva: evita restos si venían de una versión previa.
    if (_settledSnow.isNotEmpty) _settledSnow.clear();
    if (_settledRain.isNotEmpty) _settledRain.clear();

  }

  void _handleGlobalPointer(PointerEvent event) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final localPosition = renderObject.globalToLocal(event.position);
    final size = renderObject.size;
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height) {
      return;
    }

    if (event is PointerDownEvent) {
      _onPointerDown(event, localPosition);
    } else if (event is PointerMoveEvent) {
      _onPointerMove(event, localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _onPointerEnd(event);
    }
  }

  void _onPointerDown(PointerDownEvent event, Offset localPosition) {
    _emitGust(localPosition, addVelocity: false);
  }

  void _onPointerMove(PointerMoveEvent event, Offset localPosition) {
    _emitGust(localPosition, addVelocity: true);
  }

  void _onPointerEnd(PointerEvent event) {
    _lastPointer = null;
  }

  void _emitGust(Offset localPosition, {required bool addVelocity}) {
    final size = context.size;
    if (size == null || size.width <= 0 || size.height <= 0) return;

    final nowMs = _clock.elapsedMilliseconds;
    if (addVelocity && nowMs - _lastEmitMs < 24) {
      _lastPointer = localPosition;
      return;
    }
    _lastEmitMs = nowMs;

    final nx = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final ny = (localPosition.dy / size.height).clamp(0.0, 1.0);

    var vx = 0.0;
    var vy = 0.0;
    if (addVelocity && _lastPointer != null) {
      final delta = localPosition - _lastPointer!;
      vx = (delta.dx / size.width).clamp(-0.2, 0.2);
      vy = (delta.dy / size.height).clamp(-0.2, 0.2);
    }
    _lastPointer = localPosition;

    setState(() {
      _gusts.add(_SnowGust(x: nx, y: ny, vx: vx, vy: vy, bornMs: nowMs));
      if (_gusts.length > 18) {
        _gusts.removeRange(0, _gusts.length - 18);
      }
    });
  }
}

class _SnowFlake {
  double x;
  double y;
  final double radius;
  final double speed;
  final double drift;
  final int kind;
  final double toneSeed;
  final double heightSeed;

  _SnowFlake({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.kind,
    required this.toneSeed,
    required this.heightSeed,
  });
}

class _SnowPainter extends CustomPainter {
  final double driftProgress;
  final double fallProgress;
  final List<_SnowFlake> flakes;
  final List<_SettledSnow> settledSnow;
  final List<_SettledRain> settledRain;
  final List<_SnowGust> gusts;
  final Size sizeHint;
  final int nowMs;
  final double opacity;
  final double rainBlend;

  const _SnowPainter({
    required this.driftProgress,
    required this.fallProgress,
    required this.flakes,
    required this.settledSnow,
    required this.settledRain,
    required this.gusts,
    required this.sizeHint,
    required this.nowMs,
    required this.opacity,
    required this.rainBlend,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final snowPaint = Paint()..style = PaintingStyle.fill;
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final snowAccumAlpha = ((1 - rainBlend) * 0.9).clamp(0.0, 1.0);
    if (snowAccumAlpha > 0.01) {
      for (final settled in settledSnow) {
        final snowColor = Color.fromARGB(
          ((235 * snowAccumAlpha).round()).clamp(0, 255),
          242,
          247,
          252,
        );
        snowPaint.color = snowColor;
        crossPaint.color = snowColor;
        final center = Offset(
          (settled.x * size.width).clamp(0.0, size.width),
          settled.y * size.height,
        );
        if (settled.kind == 2) {
          _drawSnowflakeCrystal(
            canvas,
            center,
            settled.radius * 0.85,
            crossPaint,
            snowPaint,
          );
        } else {
          _drawSnowflakeStar(canvas, center, settled.radius * 0.9, crossPaint);
        }
      }
    }

    final rainAccumAlpha = (rainBlend * 0.9).clamp(0.0, 1.0);
    if (rainAccumAlpha > 0.01) {
      for (final settled in settledRain) {
        final center = Offset(
          (settled.x * size.width).clamp(0.0, size.width),
          settled.y * size.height,
        );
        final dropColor = _dropColorFromSeed(settled.toneSeed, rainAccumAlpha);
        final dropLength =
            (2.8 + settled.radius * 2.2) * (0.75 + settled.heightSeed * 0.45);
        final dropWidth = (1.8 + settled.radius * 1.1) * 0.9;
        _drawRaindrop(canvas, center, dropLength, dropWidth, dropColor);
      }
    }

    for (final flake in flakes) {
      final center = Offset(
        _wrap01(flake.x) * size.width,
        _wrap01(flake.y) * size.height,
      );

      final snowAlpha = (1 - rainBlend).clamp(0.0, 1.0);
      if (snowAlpha > 0.01) {
        final snowColor = Color.fromARGB(
          ((255 * opacity * snowAlpha).round()).clamp(0, 255),
          255,
          255,
          255,
        );
        snowPaint.color = snowColor;
        crossPaint.color = snowColor;
        switch (flake.kind) {
          case 1:
            _drawSnowflakeStar(canvas, center, flake.radius * 1.35, crossPaint);
            break;
          case 2:
            _drawSnowflakeCrystal(
              canvas,
              center,
              flake.radius * 1.25,
              crossPaint,
              snowPaint,
            );
            break;
          default:
            _drawSnowflakeStar(canvas, center, flake.radius * 1.15, crossPaint);
        }
      }

      final rainAlpha = rainBlend.clamp(0.0, 1.0);
      if (rainAlpha > 0.01) {
        final dropColor = _dropColorFromSeed(flake.toneSeed, rainAlpha);
        final dropLength =
            (4.2 + flake.radius * 3.2) *
            (0.72 + rainBlend * 0.58) *
            (0.75 + flake.heightSeed * 0.7);
        final dropWidth =
            (2.6 + flake.radius * 1.7) * (0.98 + rainBlend * 0.24);
        _drawRaindrop(canvas, center, dropLength, dropWidth, dropColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) {
    return oldDelegate.driftProgress != driftProgress ||
        oldDelegate.fallProgress != fallProgress ||
        oldDelegate.settledSnow.length != settledSnow.length ||
        oldDelegate.settledRain.length != settledRain.length ||
        oldDelegate.sizeHint != sizeHint ||
        oldDelegate.nowMs != nowMs ||
        oldDelegate.gusts.length != gusts.length ||
        oldDelegate.rainBlend != rainBlend;
  }

  Color _dropColorFromSeed(double toneSeed, double rainAlpha) {
    final colorBand = (toneSeed * 5).floor().clamp(0, 4);
    late final int red;
    late final int green;
    late final int blue;
    switch (colorBand) {
      case 0:
        red = (120 + toneSeed * 28).round().clamp(0, 255);
        green = (196 + toneSeed * 34).round().clamp(0, 255);
        blue = 255;
        break;
      case 1:
        red = (104 + toneSeed * 26).round().clamp(0, 255);
        green = (214 + toneSeed * 28).round().clamp(0, 255);
        blue = 255;
        break;
      case 2:
        red = (88 + toneSeed * 22).round().clamp(0, 255);
        green = (206 + toneSeed * 26).round().clamp(0, 255);
        blue = (246 + toneSeed * 9).round().clamp(0, 255);
        break;
      case 3:
        red = (96 + toneSeed * 30).round().clamp(0, 255);
        green = (170 + toneSeed * 38).round().clamp(0, 255);
        blue = 255;
        break;
      default:
        red = (148 + toneSeed * 26).round().clamp(0, 255);
        green = (164 + toneSeed * 26).round().clamp(0, 255);
        blue = 255;
    }
    return Color.fromARGB(
      ((255 * (0.55 + toneSeed * 0.28) * rainAlpha).round()).clamp(0, 255),
      red,
      green,
      blue,
    );
  }

  void _drawRaindrop(
    Canvas canvas,
    Offset center,
    double dropLength,
    double dropWidth,
    Color dropColor,
  ) {
    final topY = center.dy - dropLength * 0.56;
    final shoulderY = center.dy - dropLength * 0.14;
    final rightX = center.dx + dropWidth * 0.74;
    final leftX = center.dx - dropWidth * 0.62;

    final path = Path()
      ..moveTo(center.dx, topY)
      ..cubicTo(
        center.dx + dropWidth * 0.6,
        shoulderY - dropLength * 0.18,
        rightX + dropWidth * 0.25,
        center.dy + dropLength * 0.16,
        rightX,
        center.dy + dropLength * 0.26,
      )
      ..arcToPoint(
        Offset(leftX, center.dy + dropLength * 0.28),
        radius: Radius.elliptical(dropWidth * 0.92, dropLength * 0.35),
        clockwise: true,
      )
      ..cubicTo(
        leftX - dropWidth * 0.28,
        center.dy + dropLength * 0.06,
        center.dx - dropWidth * 0.48,
        shoulderY - dropLength * 0.22,
        center.dx,
        topY,
      )
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = dropColor;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = dropColor.withValues(alpha: dropColor.a * 0.92);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawSnowflakeStar(Canvas canvas, Offset c, double r, Paint paint) {
    final axis = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth;
    final branch = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (paint.strokeWidth * 0.82).clamp(0.8, 1.2);

    // Copo hexarradial: 6 brazos equidistantes con ramificaciones repetidas.
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      // Brazo principal
      final p1 = Offset(c.dx - dx * r * 0.14, c.dy - dy * r * 0.14);
      final p2 = Offset(c.dx + dx * r, c.dy + dy * r);
      canvas.drawLine(p1, p2, axis);

      // Dos niveles de ramas repetidas en cada brazo.
      for (final t in const [0.42, 0.68]) {
        final bx = c.dx + dx * r * t;
        final by = c.dy + dy * r * t;
        final branchLen = r * (t == 0.42 ? 0.25 : 0.18);
        final left = angle + (math.pi * 0.77);
        final right = angle - (math.pi * 0.77);
        canvas.drawLine(
          Offset(bx, by),
          Offset(
            bx + math.cos(left) * branchLen,
            by + math.sin(left) * branchLen,
          ),
          branch,
        );
        canvas.drawLine(
          Offset(bx, by),
          Offset(
            bx + math.cos(right) * branchLen,
            by + math.sin(right) * branchLen,
          ),
          branch,
        );
      }
    }

    // Núcleo pequeño para cerrar visualmente el centro.
    final core = Paint()
      ..style = PaintingStyle.fill
      ..color = paint.color.withValues(alpha: paint.color.a * 0.8);
    canvas.drawCircle(c, r * 0.12, core);
  }

  void _drawSnowflakeCrystal(
    Canvas canvas,
    Offset c,
    double r,
    Paint stroke,
    Paint fill,
  ) {
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - math.pi / 6;
      final p = Offset(
        c.dx + math.cos(a) * r * 0.56,
        c.dy + math.sin(a) * r * 0.56,
      );
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    canvas.drawPath(hex, fill..style = PaintingStyle.fill);
    canvas.drawPath(hex, stroke);
    _drawSnowflakeStar(canvas, c, r, stroke);
  }

  double _wrap01(double value) {
    if (value >= 0 && value < 1) return value;
    final wrapped = value % 1.0;
    return wrapped < 0 ? wrapped + 1.0 : wrapped;
  }
}

class _SettledSnow {
  final double x;
  final double y;
  final double radius;
  final int kind;

  const _SettledSnow({
    required this.x,
    required this.y,
    required this.radius,
    required this.kind,
  });
}

class _SettledRain {
  final double x;
  final double y;
  final double radius;
  final double toneSeed;
  final double heightSeed;

  const _SettledRain({
    required this.x,
    required this.y,
    required this.radius,
    required this.toneSeed,
    required this.heightSeed,
  });
}

class _SnowGust {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final int bornMs;

  const _SnowGust({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.bornMs,
  });
}

class _HabitList extends StatefulWidget {
  final List<Habit> habits;
  final Map<String, Completion> completions;
  final Future<void> Function(Habit habit, bool isDone) onToggle;

  const _HabitList({
    required this.habits,
    required this.completions,
    required this.onToggle,
  });

  @override
  State<_HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<_HabitList> {
  late List<Habit> _ordered;
  String? _movingHabitId;
  int _movingDirection = 0;
  int _reorderVersion = 0;

  @override
  void initState() {
    super.initState();
    _ordered = _buildSorted(widget.habits, widget.completions);
  }

  @override
  void didUpdateWidget(covariant _HabitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final habitsChanged = !listEquals(oldWidget.habits, widget.habits);
    final completionsChanged = !mapEquals(
      oldWidget.completions,
      widget.completions,
    );
    if (!habitsChanged && !completionsChanged) return;

    final nextOrdered = _buildSorted(widget.habits, widget.completions);
    if (habitsChanged) {
      _ordered = nextOrdered;
      _movingHabitId = null;
      _movingDirection = 0;
      return;
    }

    final changedHabitId = _findChangedCompletionHabitId(
      oldWidget.completions,
      widget.completions,
    );
    if (changedHabitId != null && !_sameOrder(_ordered, nextOrdered)) {
      _movingHabitId = changedHabitId;
      _movingDirection = widget.completions.containsKey(changedHabitId)
          ? 1
          : -1;
      final version = ++_reorderVersion;
      Future<void>.delayed(const Duration(milliseconds: 240), () {
        if (!mounted || version != _reorderVersion) return;
        setState(() {
          _ordered = nextOrdered;
          _movingHabitId = null;
          _movingDirection = 0;
        });
      });
    } else {
      _ordered = nextOrdered;
      _movingHabitId = null;
      _movingDirection = 0;
    }
  }

  bool _sameOrder(List<Habit> a, List<Habit> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  String? _findChangedCompletionHabitId(
    Map<String, Completion> oldCompletions,
    Map<String, Completion> newCompletions,
  ) {
    final ids = <String>{...oldCompletions.keys, ...newCompletions.keys};
    for (final id in ids) {
      final before = oldCompletions.containsKey(id);
      final after = newCompletions.containsKey(id);
      if (before != after) return id;
    }
    return null;
  }

  List<Habit> _buildSorted(
    List<Habit> habits,
    Map<String, Completion> completions,
  ) {
    final sorted = [...habits]
      ..sort((a, b) {
        final aDone = completions.containsKey(a.id);
        final bDone = completions.containsKey(b.id);
        if (aDone == bDone) {
          return a.order.compareTo(b.order);
        }
        return aDone ? 1 : -1;
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (_ordered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          96 + MediaQuery.of(context).padding.bottom,
        ),
        children: const [
          Text(
            'No hay hábitos activos.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    final indexByOrder = [...widget.habits]
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.id.compareTo(b.id);
      });
    final rankByHabitId = <String, int>{
      for (var i = 0; i < indexByOrder.length; i++) indexByOrder[i].id: i + 1,
    };

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        96 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: _ordered.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final habit = _ordered[index];
        final isDone = widget.completions.containsKey(habit.id);
        return TweenAnimationBuilder<double>(
          key: ValueKey('today-entry-${habit.id}'),
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + (index * 38)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            final clamped = value.clamp(0.0, 1.0);
            return Opacity(
              opacity: clamped,
              child: Transform.translate(
                offset: Offset(0, (1 - clamped) * 16),
                child: child,
              ),
            );
          },
          child: Dismissible(
            key: ValueKey(habit.id),
            direction: DismissDirection.horizontal,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.edit, color: Colors.white54),
            ),
            secondaryBackground: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.edit, color: Colors.white54),
            ),
            confirmDismiss: (_) async {
              context.push('/habit/${habit.id}?tab=editar');
              return false;
            },
            child: _HabitRow(
              habit: habit,
              orderNumber: rankByHabitId[habit.id] ?? habit.order,
              isDone: isDone,
              onToggle: () => widget.onToggle(habit, isDone),
              onOpenDetail: () => context.push('/habit/${habit.id}'),
              movementOffset: habit.id == _movingHabitId
                  ? Offset(0, 0.09 * _movingDirection)
                  : Offset.zero,
            ),
          ),
        );
      },
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final int orderNumber;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onOpenDetail;
  final Offset movementOffset;

  const _HabitRow({
    required this.habit,
    required this.orderNumber,
    required this.isDone,
    required this.onToggle,
    required this.onOpenDetail,
    required this.movementOffset,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    return AnimatedSlide(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      offset: movementOffset,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        onLongPress: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenDetail,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$orderNumber',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
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
                    _HabitTag(label: _habitTypeLabel(habit)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _DoneIndicator(isDone: isDone),
            ],
          ),
        ),
      ),
    );
  }
}

class _PullPlaceholder extends StatelessWidget {
  final Widget child;

  const _PullPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [SizedBox(height: 240, child: Center(child: child))],
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

class _HabitTag extends StatelessWidget {
  final String label;

  const _HabitTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
        border: Border.all(color: isDone ? accent : Colors.white24, width: 2),
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

String _monthLabelShort(int month) {
  switch (month) {
    case 1:
      return 'Ene';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Abr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Ago';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dic';
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
  required int streakDays,
  required int nextMilestoneDays,
  bool showConfetti = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) {
      return _WellDoneDialog(
        habitName: habitName,
        streakDays: streakDays,
        nextMilestoneDays: nextMilestoneDays,
        showConfetti: showConfetti,
      );
    },
  );
}

class _WellDoneDialog extends StatefulWidget {
  final String habitName;
  final int streakDays;
  final int nextMilestoneDays;
  final bool showConfetti;

  const _WellDoneDialog({
    required this.habitName,
    required this.streakDays,
    required this.nextMilestoneDays,
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
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
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
                Text(
                  'Nueva mejor racha\n${widget.streakDays} días',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 10),
                Text(
                  widget.nextMilestoneDays > 0
                      ? 'Próximo logro: ${widget.nextMilestoneDays} días'
                      : 'Has alcanzado todos los hitos',
                  style: const TextStyle(color: Colors.white38),
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
