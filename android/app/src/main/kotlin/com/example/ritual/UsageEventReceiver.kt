package com.example.ritual

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.preference.PreferenceManager
import org.json.JSONObject

class UsageEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val now = System.currentTimeMillis()

        when (action) {
            Intent.ACTION_USER_PRESENT -> {
                finalizePendingUnlock(context, now)

                val lastUnlock = prefs.getLong("dc_last_unlock", 0L)
                val sincePrev = if (lastUnlock == 0L) 0L else now - lastUnlock
                prefs.edit()
                    .putLong("dc_last_unlock", now)
                    .putLong("dc_pending_unlock", now)
                    .putLong("dc_pending_since_prev", sincePrev)
                    .apply()

                DigitalControlStore.markTrainingBreak(context, now)
            }

            Intent.ACTION_SCREEN_OFF -> finalizePendingUnlock(context, now)

            Intent.ACTION_PACKAGE_ADDED,
            Intent.ACTION_PACKAGE_REMOVED -> {
                if (!prefs.getBoolean("dc_set_instagram_detection", true)) return
                val pkg = intent.data?.schemeSpecificPart ?: return
                if (pkg != "com.instagram.android") return
                val replacing = intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)
                if (replacing) return
                val type = if (action == Intent.ACTION_PACKAGE_ADDED) "installed" else "uninstalled"
                DigitalControlStore.appendInstagramEvent(
                    context,
                    JSONObject()
                        .put("ts", now)
                        .put("type", type)
                        .put("reasonCaptured", false)
                )
            }
        }
    }

    private fun finalizePendingUnlock(context: Context, now: Long) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val pendingUnlock = prefs.getLong("dc_pending_unlock", 0L)
        if (pendingUnlock == 0L) return

        val sincePrev = prefs.getLong("dc_pending_since_prev", 0L)
        val sessionMs = (now - pendingUnlock).coerceAtLeast(0L)
        val first = UsageEventUtils.firstForegroundAfterUnlock(context, pendingUnlock, now)
        val reactiveInfo = DigitalControlStore.findLatestNotificationBeforeUnlock(context, pendingUnlock, 10_000L)
        val reactive = reactiveInfo != null
        val impulsive = sessionMs in 1..15_000
        val impulsiveConscious = impulsive && prefs.getBoolean("dc_set_impulsive_alerts", true)

        if (impulsiveConscious) {
            DigitalControlStore.maybeNotify(
                context,
                "impulsive_unlock",
                "Desbloqueo consciente",
                "¿Seguro que necesitabas abrir el móvil?",
                minGapMs = 20 * 60_000L
            )
        }
        if (reactive && prefs.getBoolean("dc_set_reactive_alerts", true)) {
            DigitalControlStore.maybeNotify(
                context,
                "reactive_unlock",
                "Desbloqueo reactivo",
                "Respira 10 segundos antes de entrar.",
                minGapMs = 20 * 60_000L
            )
        }

        val event = JSONObject()
            .put("ts", pendingUnlock)
            .put("sincePrevMs", sincePrev)
            .put("sessionMs", sessionMs)
            .put("impulsive", impulsive)
            .put("impulsiveConscious", impulsiveConscious)
            .put("reactive", reactive)
            .put("reactiveSourceApp", reactiveInfo?.optString("package") ?: JSONObject.NULL)
            .put("firstApp", first?.get("package") ?: JSONObject.NULL)
            .put("firstAppDelayMs", first?.get("delayMs") ?: JSONObject.NULL)

        DigitalControlStore.appendUnlockEvent(context, event)
        prefs.edit()
            .remove("dc_pending_unlock")
            .remove("dc_pending_since_prev")
            .apply()
    }
}
