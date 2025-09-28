package com.example.trackstatus_flutter

import io.flutter.app.FlutterApplication
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

class Application : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        
        // Create default notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "default_channel_id",
                "Default Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
