package com.example.nous

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Serviço em primeiro plano com notificação persistente na barra do Android
 * enquanto uma chamada de voz ou vídeo está ativa, permitindo retornar ao app
 * ao tocar na notificação e evitando que o sistema encerre a ligação em segundo plano.
 */
class ChamadaAtivaService : Service() {
    companion object {
        private const val CHANNEL_ID = "nous_chamada_ativa"
        private const val NOTIFICATION_ID = 9043
        const val EXTRA_NOME_CONTATO = "nomeContato"
        const val EXTRA_EH_VIDEO = "ehVideo"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val nomeContato = intent?.getStringExtra(EXTRA_NOME_CONTATO)?.takeIf { it.isNotBlank() }
            ?: "Contato Nous"
        val ehVideo = intent?.getBooleanExtra(EXTRA_EH_VIDEO, false) ?: false

        criarCanalNotificacao()
        val notificacao = construirNotificacao(nomeContato, ehVideo)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(
                NOTIFICATION_ID,
                notificacao,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
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
                    "Chamadas ativas",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Exibe a barra de status enquanto você está em chamada no Nous"
                    setSound(null, null)
                    enableVibration(false)
                }
                manager.createNotificationChannel(canal)
            }
        }
    }

    private fun construirNotificacao(nomeContato: String, ehVideo: Boolean): Notification {
        val abrirAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val contentIntent = PendingIntent.getActivity(this, 0, abrirAppIntent, pendingFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val tipoTexto = if (ehVideo) "Chamada de vídeo" else "Chamada de voz"
        return builder
            .setContentTitle("Nous — $tipoTexto em andamento")
            .setContentText("Em chamada com $nomeContato • Toque para voltar")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentIntent(contentIntent)
            .build()
    }
}
