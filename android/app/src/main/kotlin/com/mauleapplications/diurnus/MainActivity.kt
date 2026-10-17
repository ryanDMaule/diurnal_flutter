package com.mauleapplications.diurnus

import java.io.File
import kotlin.math.abs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mauleapplications.diurnus/install",
        ).setMethodCallHandler { call, result ->
            if (call.method == "isFreshInstallation") {
                result.success(consumeFreshInstallationSignal())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun consumeFreshInstallationSignal(): Boolean {
        val marker = File(noBackupFilesDir, "diurnus_install_seen")
        if (marker.exists()) return false

        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        val installedNow = abs(
            packageInfo.lastUpdateTime - packageInfo.firstInstallTime,
        ) < 2_000L
        marker.parentFile?.mkdirs()
        marker.writeText("seen")
        return installedNow
    }
}
