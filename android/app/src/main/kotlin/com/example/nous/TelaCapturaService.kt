package com.example.nous

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Serviço em primeiro plano exigido pelo Android (API 29+ / 34+) para
 * manter a captura de tela (MediaProjection) ativa sem que o sistema encerre o app.
 */
class TelaCapturaService : Service() {
    companion object {
        private const val CHANNEL_ID = "nous_captura_tela"
        private const val NOTIFICATION_ID = 9042
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        criarCanalNotificacao()
        val notificacao = construirNotificacao()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notificacao,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notificacao)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun criarCanalNotificacao() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                val canal = NotificationChannel(
                    CHANNEL_ID,
                    "Compartilhamento de tela",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Indica quando sua tela está sendo transmitida em uma chamada"
                    setSound(null, null)
                    enableVibration(false)
                }
                manager.createNotificationChannel(canal)
            }
        }
    }

    private fun construirNotificacao(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Nous — Chamada ativa")
            .setContentText("Compartilhando sua tela na chamada")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .build()
    }
}
