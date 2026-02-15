package com.example.ritual

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import java.time.Instant
import java.time.ZoneId

object UsageStatsHelper {
    fun getUsageForDay(context: Context, dayStartMs: Long, dayEndMs: Long): Map<String, Any> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val byApp = mutableMapOf<String, Long>()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, dayStartMs, dayEndMs)

        var total = 0L
        stats.forEach {
            if (it.totalTimeInForeground > 0) {
                byApp[it.packageName] = (byApp[it.packageName] ?: 0L) + it.totalTimeInForeground
                total += it.totalTimeInForeground
            }
        }

        val hourly = MutableList(24) { 0L }
        val events = usm.queryEvents(dayStartMs, dayEndMs)
        val event = UsageEvents.Event()
        val started = mutableMapOf<String, Long>()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> started[event.packageName] = event.timeStamp
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val start = started.remove(event.packageName) ?: continue
                    val span = (event.timeStamp - start).coerceAtLeast(0L)
                    val hour = Instant.ofEpochMilli(start).atZone(ZoneId.of("Europe/Madrid")).hour
                    hourly[hour] += span
                }
            }
        }

        return mapOf(
            "totalMs" to total,
            "byApp" to byApp,
            "hourlyMs" to hourly,
        )
    }

    fun isInstagramInstalled(context: Context): Boolean {
        return try {
            context.packageManager.getPackageInfo("com.instagram.android", 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }
}
