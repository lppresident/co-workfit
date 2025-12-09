package com.coworkfit.co_workfit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.coworkfit.co_workfit/health_connect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isHealthConnectInstalled" -> {
                    val isInstalled = checkHealthConnectInstalled()
                    result.success(isInstalled)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Health Connect 앱이 설치되어 있는지 확인
     * @return true if Health Connect is installed, false otherwise
     */
    private fun checkHealthConnectInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo("com.google.android.apps.healthdata", 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
