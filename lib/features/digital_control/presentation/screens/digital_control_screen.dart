import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ritual/features/digital_control/data/digital_control_service.dart';

class DigitalControlScreen extends StatefulWidget {
  const DigitalControlScreen({super.key});

  @override
  State<DigitalControlScreen> createState() => _DigitalControlScreenState();
}

class _DigitalControlScreenState extends State<DigitalControlScreen> {
  final _service = DigitalControlService();
  late Future<DigitalControlPayload> _future;
  int _windowDays = 7;
  bool _relapseModalShown = false;

  @override
  void initState() {
    super.initState();
    _future = _service.load(days: 30);
  }

  Future<void> _reload() async {
    setState(() => _future = _service.load(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de uso')),
      body: FutureBuilder<DigitalControlPayload>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            return const Center(child: CircularProgressIndicator());
          }

          final payload = snapshot.data!;
          _maybeAskRelapseReason(payload);
          final today = payload.today;
          final window = payload.summaries.length <= _windowDays
              ? payload.summaries
              : payload.summaries.sublist(payload.summaries.length - _windowDays);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _permissionCard(payload),
                const SizedBox(height: 12),
                _todayCards(today, payload),
                const SizedBox(height: 12),
                _goalsCard(payload.weeklyGoal),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 días')),
                    ButtonSegment(value: 30, label: Text('30 días')),
                  ],
                  selected: {_windowDays},
                  onSelectionChanged: (v) => setState(() => _windowDays = v.first),
                ),
                const SizedBox(height: 8),
                _weeklyChart('Desbloqueos', window, (d) => d.unlocks.toDouble()),
                _weeklyChart('% impulsivo', window, (d) => d.impulsivePct * 100),
                _weeklyChart('Uso total min', window, (d) => d.totalUsageMs / 60000),
                _weeklyChart('Índice autocontrol', window, (d) => _autocontrolScore(d, payload.training).toDouble()),
                _hourSection(today),
                _detailList(window),
                _instagramSection(payload, today),
                _trainingSection(payload),
                _interventionSettings(payload),
                Card(
                  child: ListTile(
                    title: const Text('Extensión futura'),
                    subtitle: const Text('Preparado para conectar con sistema de hábitos (sin integrar todavía).'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _maybeAskRelapseReason(DigitalControlPayload payload) {
    if (_relapseModalShown) return;
    final pending = payload.instagramEvents.where((e) => e.type == 'installed' && !e.reasonCaptured).toList();
    if (pending.isEmpty) return;
    _relapseModalShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRelapseReasonModal(pending.last);
    });
  }

  Widget _permissionCard(DigitalControlPayload payload) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Permisos requeridos'),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acceso a uso'),
              subtitle: const Text('Para desbloqueos, primera app tras desbloqueo, uso por app y resúmenes diarios.'),
              trailing: payload.hasUsageAccess
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : FilledButton(onPressed: _service.openUsageSettings, child: const Text('Ajustes')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Acceso a notificaciones (reactivos)'),
              subtitle: const Text('Para detectar desbloqueos dentro de 10 segundos tras notificación.'),
              trailing: payload.hasNotificationAccess
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : FilledButton(onPressed: _service.openNotificationAccessSettings, child: const Text('Ajustes')),
            ),
          ]),
        ),
      );

  Widget _todayCards(DailySummary d, DigitalControlPayload payload) {
    final score = _autocontrolScore(d, payload.training);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _kpi('Desbloqueos hoy', '${d.unlocks}'),
        _kpi('% impulsivo', '${(d.impulsivePct * 100).round()}%'),
        _kpi('% reactivo', '${(d.reactiveUnlockPct * 100).round()}%'),
        _kpi('Impulsivo consciente', '${d.impulsiveConsciousCount}'),
        _kpi('Récord sin desbloquear', _fmt(d.bestStreakMs)),
        _kpi('Bloques limpios', '30:${d.clean30} 60:${d.clean60} 90:${d.clean90}'),
        _kpi('Instagram first', '${d.instagramFirstCount}'),
        _kpi('Tiempo total uso', _fmt(d.totalUsageMs)),
        Tooltip(
          message: 'Índice 0-100 = 100 - desbloqueos*1.1 - %imp*0.7 - %react*0.8 - instagramFirst*2 + bloquesSemana*2',
          child: _kpi('Índice autocontrol', '$score/100'),
        ),
      ],
    );
  }

  Widget _goalsCard(WeeklyGoal goal) {
    final color = switch (goal.trafficLight) {
      'verde' => Colors.green,
      'rojo' => Colors.red,
      _ => Colors.orange,
    };
    return Card(
      child: ListTile(
        title: const Text('Objetivos dinámicos semanales'),
        subtitle: Text(
          'Desbloqueos objetivo ≤ ${goal.targetUnlocks.toStringAsFixed(1)} (actual ${goal.actualUnlocks.toStringAsFixed(1)})\n'
          'Impulsivo objetivo ≤ ${(goal.targetImpulsivePct * 100).toStringAsFixed(1)}% (actual ${(goal.actualImpulsivePct * 100).toStringAsFixed(1)}%)',
        ),
        trailing: Icon(Icons.circle, color: color),
      ),
    );
  }

  Widget _kpi(String title, String value) => SizedBox(
        width: 170,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );

  Widget _weeklyChart(String title, List<DailySummary> days, double Function(DailySummary) y) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: [for (int i = 0; i < days.length; i++) FlSpot(i.toDouble(), y(days[i]))],
                  ),
                ],
              )),
            ),
          ]),
        ),
      );

  Widget _hourSection(DailySummary d) {
    final morning = d.hourlyMs.take(8).fold<int>(0, (a, b) => a + b);
    final afternoon = d.hourlyMs.skip(8).take(8).fold<int>(0, (a, b) => a + b);
    final night = d.hourlyMs.skip(16).take(8).fold<int>(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Uso por franjas horarias (hoy)'),
          const SizedBox(height: 8),
          Text('Mañana: ${_fmt(morning)}'),
          Text('Tarde: ${_fmt(afternoon)}'),
          Text('Noche: ${_fmt(night)}'),
        ]),
      ),
    );
  }

  Widget _detailList(List<DailySummary> days) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Detalle por día (tap)'),
            for (final d in days.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${d.dayKey} · desbloqueos ${d.unlocks}'),
                subtitle: Text('Impulsivo ${(d.impulsivePct * 100).round()}% · Reactivo ${(d.reactiveUnlockPct * 100).round()}%'),
                onTap: () => _showDetail(context, d),
              ),
          ]),
        ),
      );

  Future<void> _showDetail(BuildContext context, DailySummary d) async {
    final top = d.topAppsMs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final reactiveTop = d.reactiveTopApps.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    await showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Detalle ${d.dayKey}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Desbloqueos: ${d.unlocks}'),
          Text('Media entre desbloqueos: ${_fmt(d.avgBetweenMs)}'),
          Text('Impulsivo: ${(d.impulsivePct * 100).round()}%'),
          Text('Reactivo: ${(d.reactiveUnlockPct * 100).round()}%'),
          const SizedBox(height: 8),
          const Text('Top apps por tiempo'),
          for (final app in top.take(5)) Text('${app.key}: ${_fmt(app.value)}'),
          const SizedBox(height: 6),
          const Text('Top apps reactivas'),
          for (final app in reactiveTop.take(5)) Text('${app.key}: ${app.value}'),
        ]),
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
      final uninstall = payload.instagramEvents.where((e) => e.type == 'uninstalled').toList()
        ..sort((a, b) => a.ts.compareTo(b.ts));
      if (uninstall.isNotEmpty) {
        daysWithout = now.difference(DateTime.fromMillisecondsSinceEpoch(uninstall.last.ts)).inDays + 1;
      }
    }

    final reasons = <String, int>{};
    final installEvents = payload.instagramEvents.where((e) => e.type == 'installed').toList();
    for (final e in installEvents) {
      final reason = e.reason ?? 'Sin dato';
      reasons[reason] = (reasons[reason] ?? 0) + 1;
    }
    final topReason = reasons.entries.isEmpty
        ? 'Sin datos'
        : (reasons.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

    final pairs = _buildUninstallInstallPairs(payload.instagramEvents);
    final avgRelapseMs = pairs.isEmpty
        ? null
        : pairs.map((e) => e).reduce((a, b) => a + b) ~/ pairs.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Instagram'),
          Text('Instalada: ${payload.instagramInstalled ? 'Sí' : 'No'}'),
          Text('Días consecutivos sin Instagram: $daysWithout'),
          Text('Nº recaídas últimos 30 días: $reinstalls30'),
          Text('Motivo más frecuente de reinstalación: $topReason'),
          Text('Tiempo medio entre desinstalación y reinstalación: ${avgRelapseMs == null ? 'N/D' : _fmt(avgRelapseMs)}'),
          Text('Instagram primera app hoy: ${today.instagramFirstCount}'),
          Text('Tiempo medio hasta abrir Instagram: ${today.avgTimeToInstagramMs == null ? 'N/D' : _fmt(today.avgTimeToInstagramMs!)}'),
        ]),
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
        diffs.add((e.ts - lastUninstall!).clamp(0, 1 << 31));
        lastUninstall = null;
      }
    }
    return diffs;
  }

  Widget _trainingSection(DigitalControlPayload payload) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Entrenamiento de tolerancia'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final m in const [30, 60, 90])
                OutlinedButton(
                  onPressed: payload.settings.trainingEnabled
                      ? () async {
                          await _service.startTraining(m);
                          await _reload();
                        }
                      : null,
                  child: Text('$m min'),
                ),
            ]),
            const SizedBox(height: 8),
            Text('Bloques completados esta semana: ${payload.training.blocksCompletedWeek}'),
            Text('Mejor bloque histórico: ${_fmt(payload.training.bestBlockMs)}'),
            Text('% éxito: ${(payload.training.successPct * 100).round()}%'),
            if (payload.training.trainingActive) const Text('Estado: entrenamiento activo'),
          ]),
        ),
      );

  Widget _interventionSettings(DigitalControlPayload payload) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Intervención'),
            SwitchListTile(
              value: payload.settings.impulsiveAlerts,
              onChanged: (v) async {
                await _service.updateInterventionSettings(payload.settings.copyWith(impulsiveAlerts: v));
                await _reload();
              },
              title: const Text('Avisos por desbloqueo impulsivo'),
            ),
            SwitchListTile(
              value: payload.settings.reactiveAlerts,
              onChanged: (v) async {
                await _service.updateInterventionSettings(payload.settings.copyWith(reactiveAlerts: v));
                await _reload();
              },
              title: const Text('Avisos por desbloqueos reactivos'),
            ),
            SwitchListTile(
              value: payload.settings.trainingEnabled,
              onChanged: (v) async {
                await _service.updateInterventionSettings(payload.settings.copyWith(trainingEnabled: v));
                await _reload();
              },
              title: const Text('Activar entrenamiento'),
            ),
            SwitchListTile(
              value: payload.settings.instagramDetection,
              onChanged: (v) async {
                await _service.updateInterventionSettings(payload.settings.copyWith(instagramDetection: v));
                await _reload();
              },
              title: const Text('Activar detección Instagram'),
            ),
          ]),
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
              for (final r in const ['Aburrimiento', 'Ansiedad', 'Automático', 'Trabajo', 'Otro'])
                RadioListTile<String>(
                  value: r,
                  groupValue: reason,
                  onChanged: (v) => setState(() => reason = v ?? 'Automático'),
                  title: Text(r),
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

  int _autocontrolScore(DailySummary d, TrainingStats training) {
    final value = 100 -
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
