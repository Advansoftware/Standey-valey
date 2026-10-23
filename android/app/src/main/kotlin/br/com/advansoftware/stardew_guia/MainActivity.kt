package br.com.advansoftware.stardew_guia

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.ArrayDeque

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "guia_do_vale/nsd"
        const val DISPLAY_CHANNEL = "guia_do_vale/display"
        const val UPDATER_CHANNEL = "guia_do_vale/updater"
        const val SERVICE_TYPE = "_stardewapi._tcp."
        const val SCAN_MS = 5000L
    }

    private var nsdManager: NsdManager? = null
    private var channel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private var discoveryListener: NsdManager.DiscoveryListener? = null
    private var pendingResult: MethodChannel.Result? = null
    private var found = mutableListOf<Map<String, Any>>()
    private val resolveQueue = ArrayDeque<NsdServiceInfo>()
    private var resolving = false

    private val timeout = Runnable { finishScan() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nsdManager = getSystemService(Context.NSD_SERVICE) as NsdManager
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "discover" -> startScan(result)
                "stop" -> {
                    finishScan()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISPLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepScreenOn" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        setKeepScreenOn(on)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            installApk(path, result)
                        } else {
                            result.error("invalid_arg", "Caminho não fornecido.", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("file_not_found", "Arquivo APK não existe em $path", null)
                return
            }
            val uri = FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("install_error", "Falha ao disparar instalação: ${e.message}", null)
        }
    }

    private fun setKeepScreenOn(on: Boolean) {
        runOnUiThread {
            if (on) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    private fun startScan(result: MethodChannel.Result) {
        if (pendingResult != null) {
            finishScan()
        }

        found = mutableListOf()
        resolveQueue.clear()
        resolving = false
        pendingResult = result

        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {}

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                if (!serviceInfo.serviceType.startsWith("_stardewapi._tcp")) return
                resolveQueue.addLast(serviceInfo)
                resolveNext()
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {}

            override fun onDiscoveryStopped(serviceType: String) {}

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                finishScan(errorCode, "Não foi possível iniciar a busca na rede (código $errorCode).")
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
        }
        discoveryListener = listener

        try {
            nsdManager?.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, listener)
            handler.postDelayed(timeout, SCAN_MS)
        } catch (e: Exception) {
            finishScan(null, "Não foi possível iniciar a busca na rede: ${e.message}")
        }
    }

    private fun resolveNext() {
        if (resolving || resolveQueue.isEmpty()) return
        val service = resolveQueue.removeFirst()
        resolving = true

        val listener = object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                resolving = false
                resolveNext()
            }

            override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                val host = serviceInfo.host?.hostAddress
                if (!host.isNullOrEmpty() && serviceInfo.port > 0) {
                    val already = found.any {
                        it["host"] == host && it["port"] == serviceInfo.port
                    }
                    if (!already) {
                        found.add(
                            mapOf(
                                "name" to (serviceInfo.serviceName ?: "Stardew Web API"),
                                "host" to host,
                                "port" to serviceInfo.port,
                            )
                        )
                    }
                }
                resolving = false
                resolveNext()
            }
        }

        try {
            nsdManager?.resolveService(service, listener)
        } catch (e: Exception) {
            resolving = false
            resolveNext()
        }
    }

    private fun finishScan(errorCode: Int? = null, errorMessage: String? = null) {
        handler.removeCallbacks(timeout)

        try {
            discoveryListener?.let { nsdManager?.stopServiceDiscovery(it) }
        } catch (_: Exception) {
            // A busca pode já ter sido encerrada pelo sistema.
        }
        discoveryListener = null

        val result = pendingResult ?: return
        pendingResult = null

        if (errorMessage != null) {
            result.error("nsd_failed", errorMessage, errorCode)
        } else {
            result.success(found.toList())
        }
    }

    override fun onDestroy() {
        finishScan()
        setKeepScreenOn(false)
        channel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}
