package com.example.ritual

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationTraceService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        val pkg = sbn?.packageName ?: return
        if (pkg == packageName || pkg == "com.android.systemui") return
        DigitalControlStore.appendNotificationEvent(this, pkg, System.currentTimeMillis())
    }
}
