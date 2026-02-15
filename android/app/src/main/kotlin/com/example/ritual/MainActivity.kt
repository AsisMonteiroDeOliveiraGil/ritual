package com.example.ritual

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ritual/digital_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageAccess" -> result.success(hasUsageStatsPermission())
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }
                    "hasNotificationAccess" -> result.success(DigitalControlStore.isNotificationAccessEnabled(this))
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(true)
                    }
                    "getDailySummaries" -> {
                        val startMs = call.argument<Long>("startMs") ?: 0L
                        val endMs = call.argument<Long>("endMs") ?: 0L
                        result.success(DigitalControlStore.getDailySummaries(this, startMs, endMs))
                    }
                    "getInstagramEvents" -> result.success(DigitalControlStore.getInstagramEvents(this))
                    "saveInstagramRelapseReason" -> {
                        val eventTs = call.argument<Long>("eventTs") ?: 0L
                        val reason = call.argument<String>("reason") ?: "Otro"
                        val notes = call.argument<String>("notes")
                        DigitalControlStore.saveInstagramRelapseReason(this, eventTs, reason, notes)
                        result.success(true)
                    }
                    "getInterventionSettings" -> result.success(DigitalControlStore.getSettings(this))
                    "updateInterventionSettings" -> {
                        val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                        DigitalControlStore.updateSettings(this, args)
                        result.success(true)
                    }
                    "startTraining" -> {
                        val minutes = call.argument<Int>("minutes") ?: 30
                        DigitalControlStore.startTraining(this, minutes)
                        result.success(true)
                    }
                    "getTrainingStats" -> result.success(DigitalControlStore.getTrainingStats(this))
                    "getTrackingMeta" -> result.success(
                        mapOf(
                            "usageAccess" to hasUsageStatsPermission(),
                            "notificationAccess" to DigitalControlStore.isNotificationAccessEnabled(this),
                            "instagramInstalled" to UsageStatsHelper.isInstagramInstalled(this)
                        )
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
