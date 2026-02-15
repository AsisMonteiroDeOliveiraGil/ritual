package com.example.ritual

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId

object DailySummaryAggregator {
    val madridZone: ZoneId = ZoneId.of("Europe/Madrid")

    fun computeDaySummary(
        dayStartMs: Long,
        dayEndMs: Long,
        unlockEvents: JSONArray,
        usageRow: Map<String, Any>,
        instagramInstalled: Boolean,
        instagramEvents: JSONArray
    ): JSONObject {
        val dayEvents = mutableListOf<JSONObject>()
        for (i in 0 until unlockEvents.length()) {
            val e = unlockEvents.getJSONObject(i)
            val ts = e.optLong("ts", 0L)
            if (ts in dayStartMs..dayEndMs) dayEvents.add(e)
        }

        val sincePrev = dayEvents.mapNotNull { it.optLong("sincePrevMs", 0L).takeIf { v -> v > 0L } }
        val unlocks = dayEvents.size
        val impulsive = dayEvents.count { it.optBoolean("impulsive", false) }
        val impulsiveConscious = dayEvents.count { it.optBoolean("impulsiveConscious", false) }
        val reactive = dayEvents.count { it.optBoolean("reactive", false) }
        val avgBetween = if (sincePrev.isEmpty()) 0L else sincePrev.sum() / sincePrev.size
        val bestStreak = sincePrev.maxOrNull() ?: 0L

        var c30 = 0
        var c60 = 0
        var c90 = 0
        for (gap in sincePrev) {
            if (gap >= 30 * 60_000L) c30++
            if (gap >= 60 * 60_000L) c60++
            if (gap >= 90 * 60_000L) c90++
        }

        val igFirstCount = dayEvents.count { it.optString("firstApp", "") == "com.instagram.android" }
        val igDelay = dayEvents
            .filter { it.optString("firstApp", "") == "com.instagram.android" }
            .mapNotNull { it.optLong("firstAppDelayMs", -1L).takeIf { v -> v >= 0L } }
        val igAvgDelay = if (igDelay.isEmpty()) JSONObject.NULL else igDelay.sum() / igDelay.size

        val reactiveByApp = mutableMapOf<String, Int>()
        for (e in dayEvents) {
            if (e.optBoolean("reactive", false)) {
                val app = e.optString("reactiveSourceApp", "unknown")
                reactiveByApp[app] = (reactiveByApp[app] ?: 0) + 1
            }
        }

        val reinstallsHistoric = countReinstalls(instagramEvents, Long.MIN_VALUE)
        val reinstalls7 = countReinstalls(instagramEvents, Instant.ofEpochMilli(dayStartMs).minusSeconds(6 * 86400).toEpochMilli())

        val dayKey = Instant.ofEpochMilli(dayStartMs).atZone(madridZone).toLocalDate().toString()
        return JSONObject()
            .put("dayKey", dayKey)
            .put("dayStartMs", dayStartMs)
            .put("desbloqueos_totales", unlocks)
            .put("media_tiempo_entre_desbloqueos_ms", avgBetween)
            .put("porcentaje_desbloqueos_impulsivos", if (unlocks == 0) 0.0 else impulsive.toDouble() / unlocks)
            .put("impulsivos_conscientes_count", impulsiveConscious)
            .put("reactive_unlock_count", reactive)
            .put("reactive_unlock_pct", if (unlocks == 0) 0.0 else reactive.toDouble() / unlocks)
            .put("reactive_top_apps", JSONObject(reactiveByApp.toMap()))
            .put("racha_max_sin_desbloquear_ms", bestStreak)
            .put("bloques_limpios_30", c30)
            .put("bloques_limpios_60", c60)
            .put("bloques_limpios_90", c90)
            .put("instagram_primera_app_count", igFirstCount)
            .put("instagram_instalada", instagramInstalled)
            .put("reinstalaciones_instagram_historico", reinstallsHistoric)
            .put("reinstalaciones_instagram_semana", reinstalls7)
            .put("tiempo_medio_hasta_instagram_ms", igAvgDelay)
            .put("tiempo_total_uso_ms", usageRow["totalMs"] as Long)
            .put("hourly_ms", JSONArray(usageRow["hourlyMs"] as List<Long>))
            .put("top_apps_ms", JSONObject((usageRow["byApp"] as Map<String, Long>).toMap()))
    }

    private fun countReinstalls(instagramEvents: JSONArray, fromTs: Long): Int {
        var count = 0
        for (i in 0 until instagramEvents.length()) {
            val e = instagramEvents.getJSONObject(i)
            if (e.optLong("ts", 0L) >= fromTs && e.optString("type") == "installed") count++
        }
        return count
    }
}
