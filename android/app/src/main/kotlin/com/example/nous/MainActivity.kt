package com.example.nous

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.speech.RecognizerIntent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.nous.app/instalador"
    private val CAPTURA_TELA_CHANNEL = "com.nous.app/captura_tela"
    private val REQ_CODE_VOZ = 9104
    private var vozResultPendente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAPTURA_TELA_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "iniciarServicoTela" -> {
                    try {
                        val intent = Intent(this, TelaCapturaService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERRO_SERVICO_TELA", e.message, null)
                    }
                }
                "pararServicoTela" -> {
                    try {
                        stopService(Intent(this, TelaCapturaService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERRO_SERVICO_TELA", e.message, null)
                    }
                }
                "iniciarServicoChamada" -> {
                    try {
                        val nomeContato = call.argument<String>("nomeContato") ?: "Contato Nous"
                        val ehVideo = call.argument<Boolean>("ehVideo") ?: false
                        val intent = Intent(this, ChamadaAtivaService::class.java).apply {
                            putExtra(ChamadaAtivaService.EXTRA_NOME_CONTATO, nomeContato)
                            putExtra(ChamadaAtivaService.EXTRA_EH_VIDEO, ehVideo)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERRO_SERVICO_CHAMADA", e.message, null)
                    }
                }
                "pararServicoChamada" -> {
                    try {
                        stopService(Intent(this, ChamadaAtivaService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERRO_SERVICO_CHAMADA", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
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

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                                !packageManager.canRequestPackageInstalls()
                            ) {
                                val permIntent = Intent(
                                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:${applicationContext.packageName}")
                                ).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(permIntent)
                                result.error(
                                    "PERMISSAO_INSTALACAO",
                                    "Autorize 'Instalar apps desconhecidos' para o Nous nas configurações e toque em Instalar novamente.",
                                    null
                                )
                                return@setMethodCallHandler
                            }

                            val uri = FileProvider.getUriForFile(
                                applicationContext,
                                "${applicationContext.packageName}.fileprovider",
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
                "reconhecerVoz" -> {
                    try {
                        vozResultPendente = result
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                            putExtra(
                                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                            )
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
                            putExtra(RecognizerIntent.EXTRA_PROMPT, "Fale o que deseja buscar no Nous")
                        }
                        startActivityForResult(intent, REQ_CODE_VOZ)
                    } catch (e: Exception) {
                        vozResultPendente = null
                        result.error("ERRO_VOZ", e.message, null)
                    }
                }
                "obterVersaoApp" -> {
                    try {
                        val pInfo = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                            applicationContext.packageManager.getPackageInfo(
                                applicationContext.packageName,
                                android.content.pm.PackageManager.PackageInfoFlags.of(0)
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            applicationContext.packageManager.getPackageInfo(applicationContext.packageName, 0)
                        }
                        val versao = pInfo.versionName ?: "1.0.0"
                        val build = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                            pInfo.longVersionCode.toInt()
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode
                        }
                        result.success(mapOf("versao" to versao, "build" to build))
                    } catch (e: Exception) {
                        result.error("ERRO_VERSAO", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CODE_VOZ) {
            val res = vozResultPendente
            vozResultPendente = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                val lista = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                res?.success(lista?.firstOrNull() ?: "")
            } else {
                res?.success("")
            }
        }
    }
}
