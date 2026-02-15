import 'dart:math';

import 'package:flutter/services.dart';

class DigitalControlService {
  static const _channel = MethodChannel('ritual/digital_control');

  Future<DigitalControlPayload> load({int days = 30}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    final metaRaw = (await _channel.invokeMethod<Map>('getTrackingMeta') ?? {})
        .cast<dynamic, dynamic>();

    final summariesRaw = (await _channel.invokeMethod<List>('getDailySummaries', {
          'startMs': start.millisecondsSinceEpoch,
          'endMs': now.millisecondsSinceEpoch,
        })) ??
        const [];

    final instagramEventsRaw =
        (await _channel.invokeMethod<List>('getInstagramEvents')) ?? const [];
    final settingsRaw =
        (await _channel.invokeMethod<Map>('getInterventionSettings') ?? {})
            .cast<dynamic, dynamic>();
    final trainingRaw =
        (await _channel.invokeMethod<Map>('getTrainingStats') ?? {})
            .cast<dynamic, dynamic>();

    final summaries = summariesRaw
        .map((e) => DailySummary.fromMap(Map<String, dynamic>.from(Map.from(e))))
        .toList()
      ..sort((a, b) => a.dayStartMs.compareTo(b.dayStartMs));

    final instagramEvents = instagramEventsRaw
        .map((e) => InstagramEvent.fromMap(Map<String, dynamic>.from(Map.from(e))))
        .toList();

    final settings = InterventionSettings.fromMap(
      Map<String, dynamic>.from(Map.from(settingsRaw)),
    );

    final training = TrainingStats.fromMap(
      Map<String, dynamic>.from(Map.from(trainingRaw)),
    );

    final weeklyGoal = WeeklyGoal.fromSummaries(summaries);

    return DigitalControlPayload(
      hasUsageAccess: metaRaw['usageAccess'] == true,
      hasNotificationAccess: metaRaw['notificationAccess'] == true,
      instagramInstalled: metaRaw['instagramInstalled'] == true,
      summaries: summaries,
      instagramEvents: instagramEvents,
      settings: settings,
      training: training,
      weeklyGoal: weeklyGoal,
    );
  }

  Future<void> openUsageSettings() =>
      _channel.invokeMethod('openUsageAccessSettings');

  Future<void> openNotificationAccessSettings() =>
      _channel.invokeMethod('openNotificationAccessSettings');

  Future<void> saveInstagramRelapseReason({
    required int eventTs,
    required String reason,
    String? notes,
  }) =>
      _channel.invokeMethod('saveInstagramRelapseReason', {
        'eventTs': eventTs,
        'reason': reason,
        'notes': notes,
      });

  Future<void> updateInterventionSettings(InterventionSettings settings) =>
      _channel.invokeMethod('updateInterventionSettings', settings.toMap());

  Future<void> startTraining(int minutes) =>
      _channel.invokeMethod('startTraining', {'minutes': minutes});
}

class DigitalControlPayload {
  final bool hasUsageAccess;
  final bool hasNotificationAccess;
  final bool instagramInstalled;
  final List<DailySummary> summaries;
  final List<InstagramEvent> instagramEvents;
  final InterventionSettings settings;
  final TrainingStats training;
  final WeeklyGoal weeklyGoal;

  const DigitalControlPayload({
    required this.hasUsageAccess,
    required this.hasNotificationAccess,
    required this.instagramInstalled,
    required this.summaries,
    required this.instagramEvents,
    required this.settings,
    required this.training,
    required this.weeklyGoal,
  });

  DailySummary get today {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    for (final s in summaries) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.dayStartMs);
      if (DateTime(d.year, d.month, d.day) == day) return s;
    }
    return DailySummary.empty(day);
  }
}

class DailySummary {
  final String dayKey;
  final int dayStartMs;
  final int unlocks;
  final int avgBetweenMs;
  final double impulsivePct;
  final int impulsiveConsciousCount;
  final int reactiveUnlockCount;
  final double reactiveUnlockPct;
  final Map<String, int> reactiveTopApps;
  final int bestStreakMs;
  final int clean30;
  final int clean60;
  final int clean90;
  final int instagramFirstCount;
  final bool instagramInstalled;
  final int reinstallsWeek;
  final int reinstallsHistoric;
  final int? avgTimeToInstagramMs;
  final int totalUsageMs;
  final List<int> hourlyMs;
  final Map<String, int> topAppsMs;

  const DailySummary({
    required this.dayKey,
    required this.dayStartMs,
    required this.unlocks,
    required this.avgBetweenMs,
    required this.impulsivePct,
    required this.impulsiveConsciousCount,
    required this.reactiveUnlockCount,
    required this.reactiveUnlockPct,
    required this.reactiveTopApps,
    required this.bestStreakMs,
    required this.clean30,
    required this.clean60,
    required this.clean90,
    required this.instagramFirstCount,
    required this.instagramInstalled,
    required this.reinstallsWeek,
    required this.reinstallsHistoric,
    required this.avgTimeToInstagramMs,
    required this.totalUsageMs,
    required this.hourlyMs,
    required this.topAppsMs,
  });

  factory DailySummary.empty(DateTime day) => DailySummary(
        dayKey:
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        dayStartMs: day.millisecondsSinceEpoch,
        unlocks: 0,
        avgBetweenMs: 0,
        impulsivePct: 0,
        impulsiveConsciousCount: 0,
        reactiveUnlockCount: 0,
        reactiveUnlockPct: 0,
        reactiveTopApps: const {},
        bestStreakMs: 0,
        clean30: 0,
        clean60: 0,
        clean90: 0,
        instagramFirstCount: 0,
        instagramInstalled: false,
        reinstallsWeek: 0,
        reinstallsHistoric: 0,
        avgTimeToInstagramMs: null,
        totalUsageMs: 0,
        hourlyMs: List.filled(24, 0),
        topAppsMs: const {},
      );

  factory DailySummary.fromMap(Map<String, dynamic> map) {
    List<int> hourly = List.filled(24, 0);
    final hourlyRaw = map['hourly_ms'];
    if (hourlyRaw is List) {
      final parsed = hourlyRaw.map((e) => (e as num).toInt()).toList();
      if (parsed.length == 24) hourly = parsed;
    }

    Map<String, int> _mapAny(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
      return {};
    }

    return DailySummary(
      dayKey: map['dayKey']?.toString() ?? '',
      dayStartMs: (map['dayStartMs'] as num?)?.toInt() ?? 0,
      unlocks: (map['desbloqueos_totales'] as num?)?.toInt() ?? 0,
      avgBetweenMs:
          (map['media_tiempo_entre_desbloqueos_ms'] as num?)?.toInt() ?? 0,
      impulsivePct:
          (map['porcentaje_desbloqueos_impulsivos'] as num?)?.toDouble() ?? 0,
      impulsiveConsciousCount:
          (map['impulsivos_conscientes_count'] as num?)?.toInt() ?? 0,
      reactiveUnlockCount:
          (map['reactive_unlock_count'] as num?)?.toInt() ?? 0,
      reactiveUnlockPct:
          (map['reactive_unlock_pct'] as num?)?.toDouble() ?? 0,
      reactiveTopApps: _mapAny(map['reactive_top_apps']),
      bestStreakMs:
          (map['racha_max_sin_desbloquear_ms'] as num?)?.toInt() ?? 0,
      clean30: (map['bloques_limpios_30'] as num?)?.toInt() ?? 0,
      clean60: (map['bloques_limpios_60'] as num?)?.toInt() ?? 0,
      clean90: (map['bloques_limpios_90'] as num?)?.toInt() ?? 0,
      instagramFirstCount:
          (map['instagram_primera_app_count'] as num?)?.toInt() ?? 0,
      instagramInstalled: map['instagram_instalada'] == true,
      reinstallsWeek:
          (map['reinstalaciones_instagram_semana'] as num?)?.toInt() ?? 0,
      reinstallsHistoric:
          (map['reinstalaciones_instagram_historico'] as num?)?.toInt() ?? 0,
      avgTimeToInstagramMs:
          map['tiempo_medio_hasta_instagram_ms'] == null ? null : (map['tiempo_medio_hasta_instagram_ms'] as num).toInt(),
      totalUsageMs: (map['tiempo_total_uso_ms'] as num?)?.toInt() ?? 0,
      hourlyMs: hourly,
      topAppsMs: _mapAny(map['top_apps_ms']),
    );
  }
}

class InstagramEvent {
  final int ts;
  final String type;
  final bool reasonCaptured;
  final String? reason;
  final String? notes;

  InstagramEvent({
    required this.ts,
    required this.type,
    required this.reasonCaptured,
    this.reason,
    this.notes,
  });

  factory InstagramEvent.fromMap(Map<String, dynamic> map) => InstagramEvent(
        ts: (map['ts'] as num?)?.toInt() ?? 0,
        type: map['type']?.toString() ?? 'unknown',
        reasonCaptured: map['reasonCaptured'] == true,
        reason: map['reason']?.toString(),
        notes: map['notes']?.toString(),
      );
}

class InterventionSettings {
  final bool impulsiveAlerts;
  final bool reactiveAlerts;
  final bool trainingEnabled;
  final bool instagramDetection;

  const InterventionSettings({
    required this.impulsiveAlerts,
    required this.reactiveAlerts,
    required this.trainingEnabled,
    required this.instagramDetection,
  });

  factory InterventionSettings.fromMap(Map<String, dynamic> map) =>
      InterventionSettings(
        impulsiveAlerts: map['impulsiveAlerts'] != false,
        reactiveAlerts: map['reactiveAlerts'] != false,
        trainingEnabled: map['trainingEnabled'] != false,
        instagramDetection: map['instagramDetection'] != false,
      );

  Map<String, dynamic> toMap() => {
        'impulsiveAlerts': impulsiveAlerts,
        'reactiveAlerts': reactiveAlerts,
        'trainingEnabled': trainingEnabled,
        'instagramDetection': instagramDetection,
      };

  InterventionSettings copyWith({
    bool? impulsiveAlerts,
    bool? reactiveAlerts,
    bool? trainingEnabled,
    bool? instagramDetection,
  }) =>
      InterventionSettings(
        impulsiveAlerts: impulsiveAlerts ?? this.impulsiveAlerts,
        reactiveAlerts: reactiveAlerts ?? this.reactiveAlerts,
        trainingEnabled: trainingEnabled ?? this.trainingEnabled,
        instagramDetection: instagramDetection ?? this.instagramDetection,
      );
}

class TrainingStats {
  final int blocksCompletedWeek;
  final int bestBlockMs;
  final double successPct;
  final bool trainingActive;
  final int trainingEnd;

  const TrainingStats({
    required this.blocksCompletedWeek,
    required this.bestBlockMs,
    required this.successPct,
    required this.trainingActive,
    required this.trainingEnd,
  });

  factory TrainingStats.fromMap(Map<String, dynamic> map) => TrainingStats(
        blocksCompletedWeek:
            (map['blocksCompletedWeek'] as num?)?.toInt() ?? 0,
        bestBlockMs: (map['bestBlockMs'] as num?)?.toInt() ?? 0,
        successPct: (map['successPct'] as num?)?.toDouble() ?? 0,
        trainingActive: map['trainingActive'] == true,
        trainingEnd: (map['trainingEnd'] as num?)?.toInt() ?? 0,
      );
}

class WeeklyGoal {
  final double targetUnlocks;
  final double targetImpulsivePct;
  final double actualUnlocks;
  final double actualImpulsivePct;
  final String trafficLight;

  const WeeklyGoal({
    required this.targetUnlocks,
    required this.targetImpulsivePct,
    required this.actualUnlocks,
    required this.actualImpulsivePct,
    required this.trafficLight,
  });

  factory WeeklyGoal.fromSummaries(List<DailySummary> summaries) {
    if (summaries.isEmpty) {
      return const WeeklyGoal(
        targetUnlocks: 0,
        targetImpulsivePct: 0,
        actualUnlocks: 0,
        actualImpulsivePct: 0,
        trafficLight: 'amarillo',
      );
    }
    final last7 = summaries.length <= 7
        ? summaries
        : summaries.sublist(summaries.length - 7);
    final previous7 = summaries.length <= 7
        ? last7
        : summaries.sublist(max(0, summaries.length - 14), summaries.length - 7);

    double avgUnlocks(List<DailySummary> rows) =>
        rows.isEmpty ? 0 : rows.map((e) => e.unlocks).reduce((a, b) => a + b) / rows.length;
    double avgImp(List<DailySummary> rows) => rows.isEmpty
        ? 0
        : rows.map((e) => e.impulsivePct).reduce((a, b) => a + b) / rows.length;

    final baselineUnlocks = avgUnlocks(previous7);
    final baselineImp = avgImp(previous7);

    final targetUnlocks = baselineUnlocks * 0.9;
    final targetImp = baselineImp * 0.95;
    final actualUnlocks = avgUnlocks(last7);
    final actualImp = avgImp(last7);

    String light;
    final passUnlocks = actualUnlocks <= targetUnlocks || targetUnlocks == 0;
    final passImp = actualImp <= targetImp || targetImp == 0;
    if (passUnlocks && passImp) {
      light = 'verde';
    } else if (passUnlocks || passImp) {
      light = 'amarillo';
    } else {
      light = 'rojo';
    }

    return WeeklyGoal(
      targetUnlocks: targetUnlocks,
      targetImpulsivePct: targetImp,
      actualUnlocks: actualUnlocks,
      actualImpulsivePct: actualImp,
      trafficLight: light,
    );
  }
}
