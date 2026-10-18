package com.example.nous

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nous.app/instalador"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "abrirUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERRO", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL nula", null)
                    }
                }
                "instalarApk" -> {
                    val caminho = call.argument<String>("caminho")
                    if (caminho != null) {
                        try {
                            val arquivo = File(caminho)
                            if (!arquivo.exists()) {
                                result.error("ARQUIVO_NAO_ENCONTRADO", "Arquivo APK não encontrado em: $caminho", null)
                                return@setMethodCallHandler
                            }

                            val uri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                arquivo
                            )

                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERRO_INSTALACAO", e.message, null)
                        }
                    } else {
                        result.error("CAMINHO_NULO", "Caminho do arquivo nulo", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
