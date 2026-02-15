import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ritual/features/digital_control/data/digital_control_service.dart';
import 'package:ritual/features/habits/presentation/providers/habits_providers.dart';

class DigitalControlScreen extends ConsumerStatefulWidget {
  const DigitalControlScreen({super.key});

  @override
  ConsumerState<DigitalControlScreen> createState() =>
      _DigitalControlScreenState();
}

class _DigitalControlScreenState extends ConsumerState<DigitalControlScreen> {
  final _service = DigitalControlService();
  late Future<DigitalControlPayload> _future;
  int _windowDays = 7;
  bool _relapseModalShown = false;
  bool _isDeletingAll = false;

  static const _pageBg = Color(0xFF090B12);
  static const _cardBg = Color(0xFF131826);
  static const _textPrimary = Color(0xFFF4F7FF);
  static const _textSecondary = Color(0xFFB6BED3);
  static const _stroke = Color(0xFF2A3044);
  static const _accent = Color(0xFF56E39F);
  static const _accent2 = Color(0xFF42A5F5);
  static const _accent3 = Color(0xFFFF8A65);

  @override
  void initState() {
    super.initState();
    _future = _service.load(days: 30);
  }

  Future<void> _reload() async {
    setState(() => _future = _service.load(days: 30));
  }

  Future<void> _deleteAllHabitsAndRecords() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar todo?'),
        content: const Text(
          'Esto eliminará todos los hábitos y todos los registros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeletingAll = true);
    try {
      final deleter = await ref.read(deleteAllHabitsProvider.future);
      await deleter();
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hábitos y registros eliminados')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimary,
        title: const Text('Control de uso'),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: _pageBg,
          cardColor: _cardBg,
          dividerColor: _stroke,
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: _textPrimary,
            displayColor: _textPrimary,
          ),
          listTileTheme: const ListTileThemeData(
            textColor: _textPrimary,
            iconColor: _textSecondary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: _cardBg,
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
            contentTextStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _textSecondary),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: _textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _stroke),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _accent2),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return _pageBg;
                return _textSecondary;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return _accent;
                return _cardBg;
              }),
              side: const WidgetStatePropertyAll(BorderSide(color: _stroke)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _stroke),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: const WidgetStatePropertyAll(_accent),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? _accent.withValues(alpha: 0.4)
                  : _stroke,
            ),
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _AmbientBackground()),
            FutureBuilder<DigitalControlPayload>(
              future: _future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: _textSecondary),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                }

                final payload = snapshot.data!;
                _maybeAskRelapseReason(payload);
                final today = payload.today;
                final window = payload.summaries.length <= _windowDays
                    ? payload.summaries
                    : payload.summaries.sublist(
                        payload.summaries.length - _windowDays,
                      );

                return RefreshIndicator(
                  onRefresh: _reload,
                  color: _accent,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _heroPanel(today, payload),
                      const SizedBox(height: 12),
                      if (!payload.hasUsageAccess ||
                          !payload.hasNotificationAccess)
                        _permissionCard(payload),
                      if (!payload.hasUsageAccess ||
                          !payload.hasNotificationAccess)
                        const SizedBox(height: 12),
                      _todayCards(today, payload),
                      const SizedBox(height: 12),
                      _goalsCard(payload.weeklyGoal),
                      const SizedBox(height: 16),
                      _sectionTitle('Tendencias'),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('7 días')),
                          ButtonSegment(value: 30, label: Text('30 días')),
                        ],
                        selected: {_windowDays},
                        onSelectionChanged: (v) =>
                            setState(() => _windowDays = v.first),
                      ),
                      const SizedBox(height: 10),
                      _weeklyChart(
                        'Desbloqueos',
                        window,
                        (d) => d.unlocks.toDouble(),
                        color: _accent3,
                      ),
                      _weeklyChart(
                        '% impulsivo',
                        window,
                        (d) => d.impulsivePct * 100,
                        color: _accent2,
                      ),
                      _weeklyChart(
                        'Uso total (min)',
                        window,
                        (d) => d.totalUsageMs / 60000,
                        color: _accent,
                      ),
                      _weeklyChart(
                        'Índice autocontrol',
                        window,
                        (d) =>
                            _autocontrolScore(d, payload.training).toDouble(),
                        color: const Color(0xFFFFD166),
                      ),
                      const SizedBox(height: 12),
                      _hourSection(today),
                      const SizedBox(height: 12),
                      _detailList(window),
                      const SizedBox(height: 12),
                      _instagramSection(payload, today),
                      const SizedBox(height: 12),
                      _trainingSection(payload),
                      const SizedBox(height: 12),
                      _interventionSettings(payload),
                      const SizedBox(height: 12),
                      _dangerZone(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _maybeAskRelapseReason(DigitalControlPayload payload) {
    if (_relapseModalShown) return;
    final pending = payload.instagramEvents
        .where((e) => e.type == 'installed' && !e.reasonCaptured)
        .toList();
    if (pending.isEmpty) return;
    _relapseModalShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRelapseReasonModal(pending.last);
    });
  }

  Widget _heroPanel(DailySummary d, DigitalControlPayload payload) {
    final score = _autocontrolScore(d, payload.training);
    final scoreNorm = (score / 100).clamp(0, 1).toDouble();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu foco de hoy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Desbloqueos ${d.unlocks} · Impulsivo ${(d.impulsivePct * 100).round()}%',
                      style: const TextStyle(color: _textSecondary),
                    ),
                    const SizedBox(height: 10),
                    _pill(
                      icon: Icons.timer_outlined,
                      text: 'Uso total ${_fmt(d.totalUsageMs)}',
                    ),
                  ],
                ),
              ),
              _ScoreRing(value: scoreNorm, score: score),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: scoreNorm,
              backgroundColor: _stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard(DigitalControlPayload payload) => _glassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Permisos requeridos'),
        const SizedBox(height: 8),
        _permissionTile(
          title: 'Acceso a uso',
          subtitle:
              'Desbloqueos, primera app, tiempo por app y resúmenes diarios.',
          ok: payload.hasUsageAccess,
          onTap: _service.openUsageSettings,
        ),
        const SizedBox(height: 8),
        _permissionTile(
          title: 'Acceso a notificaciones',
          subtitle: 'Detecta desbloqueos reactivos en ventana de 10 segundos.',
          ok: payload.hasNotificationAccess,
          onTap: _service.openNotificationAccessSettings,
        ),
      ],
    ),
  );

  Widget _permissionTile({
    required String title,
    required String subtitle,
    required bool ok,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1320),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _stroke),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: _textSecondary)),
        trailing: ok
            ? const Icon(Icons.check_circle, color: _accent)
            : FilledButton(onPressed: onTap, child: const Text('Activar')),
      ),
    );
  }

  Widget _todayCards(DailySummary d, DigitalControlPayload payload) {
    final score = _autocontrolScore(d, payload.training);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _kpi('Desbloqueos', '${d.unlocks}', Icons.lock_open_rounded),
        _kpi('% impulsivo', '${(d.impulsivePct * 100).round()}%', Icons.bolt),
        _kpi(
          '% reactivo',
          '${(d.reactiveUnlockPct * 100).round()}%',
          Icons.notifications_active_outlined,
        ),
        _kpi(
          'Impulsivo consciente',
          '${d.impulsiveConsciousCount}',
          Icons.psychology_alt_outlined,
        ),
        _kpi(
          'Récord sin desbloquear',
          _fmt(d.bestStreakMs),
          Icons.flag_outlined,
        ),
        _kpi(
          'Bloques limpios',
          '30:${d.clean30} 60:${d.clean60} 90:${d.clean90}',
          Icons.grid_view_rounded,
        ),
        _kpi(
          'Instagram first',
          '${d.instagramFirstCount}',
          Icons.photo_camera_front_outlined,
        ),
        _kpi('Tiempo total', _fmt(d.totalUsageMs), Icons.av_timer_rounded),
        Tooltip(
          message:
              'Índice 0-100 = 100 - desbloqueos*1.1 - %imp*0.7 - %react*0.8 - instagramFirst*2 + bloquesSemana*2',
          child: _kpi(
            'Índice autocontrol',
            '$score/100',
            Icons.auto_graph_rounded,
          ),
        ),
      ],
    );
  }

  Widget _goalsCard(WeeklyGoal goal) {
    final color = switch (goal.trafficLight) {
      'verde' => _accent,
      'rojo' => Colors.redAccent,
      _ => const Color(0xFFFFB74D),
    };

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Objetivos dinámicos semanales',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Icon(Icons.circle, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          _goalRow(
            'Desbloqueos objetivo',
            '≤ ${goal.targetUnlocks.toStringAsFixed(1)}',
            'Actual ${goal.actualUnlocks.toStringAsFixed(1)}',
          ),
          const SizedBox(height: 8),
          _goalRow(
            'Impulsivo objetivo',
            '≤ ${(goal.targetImpulsivePct * 100).toStringAsFixed(1)}%',
            'Actual ${(goal.actualImpulsivePct * 100).toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }

  Widget _goalRow(String title, String target, String current) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: _textSecondary)),
          ),
          Text(target, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(current, style: const TextStyle(color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _kpi(String title, String value, IconData icon) => SizedBox(
    width: 170,
    child: _glassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _accent2),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: _textSecondary)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _weeklyChart(
    String title,
    List<DailySummary> days,
    double Function(DailySummary) y, {
    required Color color,
  }) {
    final points = [
      for (int i = 0; i < days.length; i++) FlSpot(i.toDouble(), y(days[i])),
    ];

    return _glassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(0, points.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _niceInterval(points),
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0x332A3044), strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    spots: points,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.35),
                          color.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: points.length < 10,
                      getDotPainter: (spot, spotPercent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 2.4,
                            color: color,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _niceInterval(List<FlSpot> points) {
    if (points.isEmpty) return 1;
    final maxY = points.map((e) => e.y).reduce(math.max);
    if (maxY <= 6) return 1;
    if (maxY <= 25) return 5;
    if (maxY <= 100) return 10;
    return 20;
  }

  Widget _hourSection(DailySummary d) {
    final morning = d.hourlyMs.take(8).fold<int>(0, (a, b) => a + b);
    final afternoon = d.hourlyMs.skip(8).take(8).fold<int>(0, (a, b) => a + b);
    final night = d.hourlyMs.skip(16).take(8).fold<int>(0, (a, b) => a + b);
    final maxV = [morning, afternoon, night].reduce(math.max).toDouble();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Uso por franjas (hoy)'),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                maxY: maxV == 0 ? 1 : maxV * 1.2,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const labels = ['Mañana', 'Tarde', 'Noche'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _bar(0, morning.toDouble(), _accent2),
                  _bar(1, afternoon.toDouble(), _accent),
                  _bar(2, night.toDouble(), _accent3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniPill('Mañana ${_fmt(morning)}', _accent2),
              _miniPill('Tarde ${_fmt(afternoon)}', _accent),
              _miniPill('Noche ${_fmt(night)}', _accent3),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 24,
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }

  Widget _detailList(List<DailySummary> days) => _glassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Detalle diario'),
        const SizedBox(height: 8),
        for (final d in days.reversed)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1320),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _stroke),
            ),
            child: ListTile(
              title: Text('${d.dayKey} · desbloqueos ${d.unlocks}'),
              subtitle: Text(
                'Impulsivo ${(d.impulsivePct * 100).round()}% · Reactivo ${(d.reactiveUnlockPct * 100).round()}%',
                style: const TextStyle(color: _textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showDetail(context, d),
            ),
          ),
      ],
    ),
  );

  Future<void> _showDetail(BuildContext context, DailySummary d) async {
    final top = d.topAppsMs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final reactiveTop = d.reactiveTopApps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalle ${d.dayKey}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    icon: Icons.lock_open,
                    text: 'Desbloqueos ${d.unlocks}',
                  ),
                  _pill(
                    icon: Icons.timelapse,
                    text: 'Media ${_fmt(d.avgBetweenMs)}',
                  ),
                  _pill(
                    icon: Icons.flash_on,
                    text: 'Impulsivo ${(d.impulsivePct * 100).round()}%',
                  ),
                  _pill(
                    icon: Icons.notifications,
                    text: 'Reactivo ${(d.reactiveUnlockPct * 100).round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Top apps por tiempo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final app in top.take(5))
                Text(
                  '${app.key}: ${_fmt(app.value)}',
                  style: const TextStyle(color: _textSecondary),
                ),
              const SizedBox(height: 10),
              const Text(
                'Top apps reactivas',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final app in reactiveTop.take(5))
                Text(
                  '${app.key}: ${app.value}',
                  style: const TextStyle(color: _textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _instagramSection(DigitalControlPayload payload, DailySummary today) {
    final now = DateTime.now();
    final reinstalls30 = payload.instagramEvents.where((e) {
      final ts = DateTime.fromMillisecondsSinceEpoch(e.ts);
      return e.type == 'installed' && now.difference(ts).inDays <= 30;
    }).length;

    int daysWithout = 0;
    if (!payload.instagramInstalled) {
      final uninstall =
          payload.instagramEvents.where((e) => e.type == 'uninstalled').toList()
            ..sort((a, b) => a.ts.compareTo(b.ts));
      if (uninstall.isNotEmpty) {
        daysWithout =
            now
                .difference(
                  DateTime.fromMillisecondsSinceEpoch(uninstall.last.ts),
                )
                .inDays +
            1;
      }
    }

    final reasons = <String, int>{};
    final installEvents = payload.instagramEvents
        .where((e) => e.type == 'installed')
        .toList();
    for (final e in installEvents) {
      final reason = e.reason ?? 'Sin dato';
      reasons[reason] = (reasons[reason] ?? 0) + 1;
    }
    final topReason = reasons.entries.isEmpty
        ? 'Sin datos'
        : (reasons.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    final pairs = _buildUninstallInstallPairs(payload.instagramEvents);
    final avgRelapseMs = pairs.isEmpty
        ? null
        : pairs.map((e) => e).reduce((a, b) => a + b) ~/ pairs.length;
    final avgTimeToInstagramMs = today.avgTimeToInstagramMs;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Instagram'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniPill(
                'Instalada: ${payload.instagramInstalled ? 'Sí' : 'No'}',
                payload.instagramInstalled ? _accent3 : _accent,
              ),
              _miniPill('Días sin Instagram: $daysWithout', _accent2),
              _miniPill('Recaídas 30d: $reinstalls30', _accent3),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Motivo más frecuente: $topReason',
            style: const TextStyle(color: _textSecondary),
          ),
          Text(
            'Media desinstalar → reinstalar: ${avgRelapseMs == null ? 'N/D' : _fmt(avgRelapseMs)}',
            style: const TextStyle(color: _textSecondary),
          ),
          Text(
            'Instagram primera app hoy: ${today.instagramFirstCount}',
            style: const TextStyle(color: _textSecondary),
          ),
          Text(
            'Tiempo medio hasta Instagram: ${avgTimeToInstagramMs == null ? 'N/D' : _fmt(avgTimeToInstagramMs)}',
            style: const TextStyle(color: _textSecondary),
          ),
        ],
      ),
    );
  }

  List<int> _buildUninstallInstallPairs(List<InstagramEvent> events) {
    final sorted = [...events]..sort((a, b) => a.ts.compareTo(b.ts));
    int? lastUninstall;
    final diffs = <int>[];
    for (final e in sorted) {
      if (e.type == 'uninstalled') lastUninstall = e.ts;
      if (e.type == 'installed' && lastUninstall != null) {
        diffs.add((e.ts - lastUninstall).clamp(0, 1 << 31));
        lastUninstall = null;
      }
    }
    return diffs;
  }

  Widget _trainingSection(DigitalControlPayload payload) => _glassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Entrenamiento de tolerancia'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in const [30, 60, 90])
              FilledButton.tonal(
                onPressed: payload.settings.trainingEnabled
                    ? () async {
                        await _service.startTraining(m);
                        await _reload();
                      }
                    : null,
                style: FilledButton.styleFrom(
                  foregroundColor: _textPrimary,
                  backgroundColor: const Color(0xFF0E2331),
                ),
                child: Text('$m min'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _miniPill(
              'Bloques semana: ${payload.training.blocksCompletedWeek}',
              _accent,
            ),
            _miniPill(
              'Mejor bloque: ${_fmt(payload.training.bestBlockMs)}',
              _accent2,
            ),
            _miniPill(
              'Éxito: ${(payload.training.successPct * 100).round()}%',
              _accent3,
            ),
          ],
        ),
        if (payload.training.trainingActive)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Estado: entrenamiento activo',
              style: TextStyle(color: _accent),
            ),
          ),
      ],
    ),
  );

  Widget _interventionSettings(DigitalControlPayload payload) => _glassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Intervención'),
        const SizedBox(height: 4),
        _switchTile(
          value: payload.settings.impulsiveAlerts,
          onChanged: (v) async {
            await _service.updateInterventionSettings(
              payload.settings.copyWith(impulsiveAlerts: v),
            );
            await _reload();
          },
          title: 'Avisos por desbloqueo impulsivo',
        ),
        _switchTile(
          value: payload.settings.reactiveAlerts,
          onChanged: (v) async {
            await _service.updateInterventionSettings(
              payload.settings.copyWith(reactiveAlerts: v),
            );
            await _reload();
          },
          title: 'Avisos por desbloqueos reactivos',
        ),
        _switchTile(
          value: payload.settings.trainingEnabled,
          onChanged: (v) async {
            await _service.updateInterventionSettings(
              payload.settings.copyWith(trainingEnabled: v),
            );
            await _reload();
          },
          title: 'Activar entrenamiento',
        ),
        _switchTile(
          value: payload.settings.instagramDetection,
          onChanged: (v) async {
            await _service.updateInterventionSettings(
              payload.settings.copyWith(instagramDetection: v),
            );
            await _reload();
          },
          title: 'Activar detección Instagram',
        ),
      ],
    ),
  );

  Widget _switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1320),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _stroke),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
      ),
    );
  }

  Widget _dangerZone() => _glassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danger zone',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x24FF5252),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x66FF5252)),
          ),
          child: ListTile(
            title: const Text('Eliminar todos los hábitos y registros'),
            subtitle: const Text(
              'Acción irreversible',
              style: TextStyle(color: _textSecondary),
            ),
            trailing: _isDeletingAll
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton.icon(
                    onPressed: _deleteAllHabitsAndRecords,
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Eliminar todo'),
                  ),
          ),
        ),
      ],
    ),
  );

  Future<void> _showRelapseReasonModal(InstagramEvent event) async {
    String reason = 'Automático';
    final notesController = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¿Qué ha pasado?'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => setState(() => reason = v ?? 'Automático'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in const [
                      'Aburrimiento',
                      'Ansiedad',
                      'Automático',
                      'Trabajo',
                      'Otro',
                    ])
                      RadioListTile<String>(value: r, title: Text(r)),
                  ],
                ),
              ),
              if (reason == 'Otro')
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Texto libre'),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              await _service.saveInstagramRelapseReason(
                eventTs: event.ts,
                reason: reason,
                notes: reason == 'Otro' ? notesController.text.trim() : null,
              );
              if (mounted) Navigator.of(context).pop();
              await _reload();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xAA151B2A), Color(0xAA101524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
  );

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF0E1321),
        border: Border.all(color: _stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _accent2),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _miniPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12.5)),
    );
  }

  int _autocontrolScore(DailySummary d, TrainingStats training) {
    final value =
        100 -
        (d.unlocks * 1.1) -
        (d.impulsivePct * 100 * 0.7) -
        (d.reactiveUnlockPct * 100 * 0.8) -
        (d.instagramFirstCount * 2) +
        (training.blocksCompletedWeek * 2);
    return value.clamp(0, 100).round();
  }

  String _fmt(int ms) {
    if (ms <= 0) return '0m';
    final totalMin = ms ~/ 60000;
    if (totalMin < 1) return '${(ms / 1000).round()}s';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF090B12), Color(0xFF0D1422), Color(0xFF090B12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _glow(const Color(0xFF2EC4B6), 220),
          ),
          Positioned(
            top: 120,
            right: -70,
            child: _glow(const Color(0xFF42A5F5), 240),
          ),
          Positioned(
            bottom: -90,
            left: 30,
            child: _glow(const Color(0xFFFF8A65), 260),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.32), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.value, required this.score});

  final double value;
  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: animated,
                strokeWidth: 8,
                backgroundColor: const Color(0xFF2A3044),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF56E39F)),
              ),
              Center(
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
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
