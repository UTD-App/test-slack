package com.audio_room

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.ComponentCallbacks2
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class AudioRoomPlugin : FlutterPlugin, ActivityAware {

    private lateinit var pipChannel: MethodChannel
    private lateinit var pipStateChannel: MethodChannel

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var shouldEnterPip = false
    private var wasInPipMode = false

    // ── FlutterPlugin ──

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pipChannel = MethodChannel(binding.binaryMessenger, "pip_channel")
        pipChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableAutoPip" -> { shouldEnterPip = true; result.success(true) }
                "disableAutoPip" -> { shouldEnterPip = false; result.success(true) }
                "enterPip" -> result.success(enterPipMode())
                else -> result.notImplemented()
            }
        }

        pipStateChannel = MethodChannel(binding.binaryMessenger, "pip_state_channel")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pipChannel.setMethodCallHandler(null)
    }

    // ── ActivityAware ──

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnUserLeaveHintListener(userLeaveHintListener)
        registerComponentCallbacks()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnUserLeaveHintListener(userLeaveHintListener)
        unregisterComponentCallbacks()
        activity = null
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    // ── PiP ──

    private val userLeaveHintListener = PluginRegistry.UserLeaveHintListener {
        if (shouldEnterPip) enterPipMode()
    }

    private fun enterPipMode(): Boolean {
        val act = activity ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val params = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(9, 10))
            .build()
        return act.enterPictureInPictureMode(params)
    }

    // ── PiP state detection ──

    private val componentCallbacks = object : ComponentCallbacks2 {
        override fun onConfigurationChanged(newConfig: Configuration) {
            val act = activity ?: return
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val isInPip = act.isInPictureInPictureMode
            if (isInPip != wasInPipMode) {
                wasInPipMode = isInPip
                pipStateChannel.invokeMethod(
                    if (isInPip) "enteredPiP" else "exitedPiP", null
                )
            }
        }
        override fun onLowMemory() {}
        override fun onTrimMemory(level: Int) {}
    }

    private fun registerComponentCallbacks() {
        activity?.registerComponentCallbacks(componentCallbacks)
    }

    private fun unregisterComponentCallbacks() {
        activity?.unregisterComponentCallbacks(componentCallbacks)
    }
}
