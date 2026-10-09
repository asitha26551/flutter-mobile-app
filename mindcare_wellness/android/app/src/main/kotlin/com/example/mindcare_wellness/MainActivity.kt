package com.example.mindcare_wellness

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mindcare/onboarding")
            .setMethodCallHandler { call, result ->
                val preferences = getSharedPreferences("mindcare_intro", Context.MODE_PRIVATE)
                when (call.method) {
                    "hasCompleted" -> result.success(preferences.getBoolean("completed", false))
                    "markCompleted" -> result.success(
                        preferences.edit().putBoolean("completed", true).commit()
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
