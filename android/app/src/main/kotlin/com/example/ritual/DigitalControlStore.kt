package com.example.ritual

import android.content.Context
import android.provider.Settings
import androidx.preference.PreferenceManager
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

object DigitalControlStore {
    private const val unlockKey = "dc_unlock_events"
    private const val instagramKey = "dc_instagram_events"
    private const val summariesKey = "dc_daily_summaries"
    private const val notifEventsKey = "dc_notification_events"
    private const val trainingSessionsKey = "dc_training_sessions"

    fun appendUnlockEvent(context: Context, event: JSONObject) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val array = JSONArray(prefs.getString(unlockKey, "[]"))
        array.put(event)
        prefs.edit().putString(unlockKey, trimArray(array, 12_000).toString()).apply()
    }

    fun appendInstagramEvent(context: Context, event: JSONObject) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val array = JSONArray(prefs.getString(instagramKey, "[]"))
        array.put(event)
        prefs.edit().putString(instagramKey, trimArray(array, 200).toString()).apply()
    }

    fun appendNotificationEvent(context: Context, pkg: String, ts: Long) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val array = JSONArray(prefs.getString(notifEventsKey, "[]"))
        array.put(JSONObject().put("package", pkg).put("ts", ts))
        prefs.edit().putString(notifEventsKey, trimArray(array, 2_000).toString()).apply()
    }

    fun findLatestNotificationBeforeUnlock(context: Context, unlockTs: Long, windowMs: Long): JSONObject? {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val array = JSONArray(prefs.getString(notifEventsKey, "[]"))
        var best: JSONObject? = null
        for (i in 0 until array.length()) {
            val e = array.getJSONObject(i)
            val ts = e.optLong("ts", 0L)
            if (ts <= unlockTs && unlockTs - ts <= windowMs) best = e
        }
        return best
    }

    fun getDailySummaries(context: Context, startMs: Long, endMs: Long): List<Map<String, Any?>> {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val unlockEvents = JSONArray(prefs.getString(unlockKey, "[]"))
        val instagramEvents = JSONArray(prefs.getString(instagramKey, "[]"))
        val cached = JSONObject(prefs.getString(summariesKey, "{}"))

        var day = Instant.ofEpochMilli(startMs).atZone(DailySummaryAggregator.madridZone).toLocalDate()
        val endDay = Instant.ofEpochMilli(endMs).atZone(DailySummaryAggregator.madridZone).toLocalDate()
        while (!day.isAfter(endDay)) {
            val dayStart = day.atStartOfDay(DailySummaryAggregator.madridZone).toInstant().toEpochMilli()
            val dayEnd = day.plusDays(1).atStartOfDay(DailySummaryAggregator.madridZone).toInstant().toEpochMilli() - 1
            val usageRow = UsageStatsHelper.getUsageForDay(context, dayStart, dayEnd)
            val summary = DailySummaryAggregator.computeDaySummary(
                dayStart,
                dayEnd,
                unlockEvents,
                usageRow,
                UsageStatsHelper.isInstagramInstalled(context),
                instagramEvents
            )
            cached.put(summary.getString("dayKey"), summary)
            day = day.plusDays(1)
        }
        prefs.edit().putString(summariesKey, cached.toString()).apply()

        val out = mutableListOf<Map<String, Any?>>()
        val keys = cached.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val obj = cached.getJSONObject(key)
            val start = obj.optLong("dayStartMs", 0L)
            if (start in startMs..endMs) out.add(jsonObjectToMap(obj))
        }
        return out.sortedBy { (it["dayStartMs"] as Number).toLong() }
    }

    fun getInstagramEvents(context: Context): List<Map<String, Any?>> {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        return jsonArrayToList(JSONArray(prefs.getString(instagramKey, "[]")))
    }

    fun saveInstagramRelapseReason(context: Context, eventTs: Long, reason: String, notes: String?) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val array = JSONArray(prefs.getString(instagramKey, "[]"))
        for (i in 0 until array.length()) {
            val e = array.getJSONObject(i)
            if (e.optLong("ts", -1L) == eventTs) {
                e.put("reason", reason)
                e.put("notes", notes ?: JSONObject.NULL)
                e.put("reasonCaptured", true)
            }
        }
        prefs.edit().putString(instagramKey, array.toString()).apply()
    }

    fun getSettings(context: Context): Map<String, Any> {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        return mapOf(
            "impulsiveAlerts" to prefs.getBoolean("dc_set_impulsive_alerts", true),
            "reactiveAlerts" to prefs.getBoolean("dc_set_reactive_alerts", true),
            "trainingEnabled" to prefs.getBoolean("dc_set_training_enabled", true),
            "instagramDetection" to prefs.getBoolean("dc_set_instagram_detection", true)
        )
    }

    fun updateSettings(context: Context, payload: Map<String, Any?>) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        prefs.edit().apply {
            payload["impulsiveAlerts"]?.let { putBoolean("dc_set_impulsive_alerts", it as Boolean) }
            payload["reactiveAlerts"]?.let { putBoolean("dc_set_reactive_alerts", it as Boolean) }
            payload["trainingEnabled"]?.let { putBoolean("dc_set_training_enabled", it as Boolean) }
            payload["instagramDetection"]?.let { putBoolean("dc_set_instagram_detection", it as Boolean) }
        }.apply()
    }

    fun startTraining(context: Context, durationMin: Int) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val now = System.currentTimeMillis()
        prefs.edit()
            .putLong("dc_training_start", now)
            .putLong("dc_training_end", now + durationMin * 60_000L)
            .putBoolean("dc_training_active", true)
            .putBoolean("dc_training_broken", false)
            .apply()
    }

    fun markTrainingBreak(context: Context, ts: Long) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        if (!prefs.getBoolean("dc_training_active", false)) return
        prefs.edit().putBoolean("dc_training_broken", true).apply()
        maybeNotify(context, "training_break", "Entrenamiento", "Sigue aguantando.", minGapMs = 10 * 60_000L)
        finalizeTrainingIfEnded(context, ts)
    }

    fun finalizeTrainingIfEnded(context: Context, now: Long = System.currentTimeMillis()) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val active = prefs.getBoolean("dc_training_active", false)
        if (!active) return
        val end = prefs.getLong("dc_training_end", 0L)
        if (now < end) return

        val start = prefs.getLong("dc_training_start", 0L)
        val broken = prefs.getBoolean("dc_training_broken", false)
        val sessions = JSONArray(prefs.getString(trainingSessionsKey, "[]"))
        sessions.put(
            JSONObject()
                .put("start", start)
                .put("end", end)
                .put("success", !broken)
                .put("durationMs", (end - start).coerceAtLeast(0L))
        )
        prefs.edit()
            .putString(trainingSessionsKey, trimArray(sessions, 500).toString())
            .putBoolean("dc_training_active", false)
            .putBoolean("dc_training_broken", false)
            .apply()
    }

    fun getTrainingStats(context: Context): Map<String, Any> {
        finalizeTrainingIfEnded(context)
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val sessions = JSONArray(prefs.getString(trainingSessionsKey, "[]"))
        val now = Instant.now().atZone(DailySummaryAggregator.madridZone)
        val weekStart = now.toLocalDate().minusDays((now.dayOfWeek.value - 1).toLong())
            .atStartOfDay(DailySummaryAggregator.madridZone).toInstant().toEpochMilli()

        var weekCompleted = 0
        var total = 0
        var success = 0
        var best = 0L
        for (i in 0 until sessions.length()) {
            val s = sessions.getJSONObject(i)
            val ok = s.optBoolean("success", false)
            val end = s.optLong("end", 0L)
            val duration = s.optLong("durationMs", 0L)
            total++
            if (ok) {
                success++
                best = maxOf(best, duration)
                if (end >= weekStart) weekCompleted++
            }
        }

        return mapOf(
            "blocksCompletedWeek" to weekCompleted,
            "bestBlockMs" to best,
            "successPct" to if (total == 0) 0.0 else success.toDouble() / total,
            "trainingActive" to prefs.getBoolean("dc_training_active", false),
            "trainingEnd" to prefs.getLong("dc_training_end", 0L)
        )
    }

    fun isNotificationAccessEnabled(context: Context): Boolean {
        val enabled = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners") ?: return false
        return enabled.contains(context.packageName)
    }

    fun maybeNotify(context: Context, key: String, title: String, body: String, minGapMs: Long = 15 * 60_000L) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val now = System.currentTimeMillis()
        val last = prefs.getLong("dc_last_notify_$key", 0L)
        if (now - last < minGapMs) return
        prefs.edit().putLong("dc_last_notify_$key", now).apply()
        SoftAlertNotifier.send(context, title, body)
    }

    private fun trimArray(array: JSONArray, keep: Int): JSONArray {
        val start = (array.length() - keep).coerceAtLeast(0)
        val out = JSONArray()
        for (i in start until array.length()) out.put(array.get(i))
        return out
    }

    private fun jsonArrayToList(array: JSONArray): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        for (i in 0 until array.length()) out.add(jsonObjectToMap(array.getJSONObject(i)))
        return out
    }

    private fun jsonObjectToMap(obj: JSONObject): Map<String, Any?> {
        val out = mutableMapOf<String, Any?>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = obj.get(key)
            out[key] = when (value) {
                is JSONObject -> jsonObjectToMap(value)
                is JSONArray -> (0 until value.length()).map { idx -> value.get(idx) }
                JSONObject.NULL -> null
                else -> value
            }
        }
        return out
    }
}
