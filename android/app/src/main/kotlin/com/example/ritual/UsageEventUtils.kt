package com.example.ritual

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context

object UsageEventUtils {
    fun firstForegroundAfterUnlock(context: Context, unlockTs: Long, endTs: Long): Map<String, Any>? {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(unlockTs, endTs)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            ) {
                val pkg = event.packageName ?: continue
                if (pkg != context.packageName && pkg != "com.android.systemui") {
                    return mapOf(
                        "package" to pkg,
                        "delayMs" to (event.timeStamp - unlockTs).coerceAtLeast(0L)
                    )
                }
            }
        }
        return null
    }
}
