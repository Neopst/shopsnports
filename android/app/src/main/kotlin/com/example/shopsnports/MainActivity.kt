package com.example.shopsnports

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "shopsnports/deeplink"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "getInitialLink") {
				val intent: Intent? = intent
				val data: Uri? = intent?.data
				if (data != null) {
					result.success(data.toString())
				} else {
					result.success(null)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
