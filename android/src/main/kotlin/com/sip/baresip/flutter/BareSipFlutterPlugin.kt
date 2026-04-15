package com.sip.baresip.flutter

import android.content.Context
import com.sip.baresipsdk.AudioRoute
import com.sip.baresipsdk.BareSipSdk
import com.sip.baresipsdk.CallManager
import com.sip.baresipsdk.SdkAudioManager
import com.sip.baresipsdk.SdkConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BareSipFlutterPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: Context
    private val streamHandler = SdkStreamHandler()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "com.sip.baresip/commands")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.sip.baresip/events")
        eventChannel.setStreamHandler(streamHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        streamHandler.onCancel(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != "initialize" && !BareSipSdk.isInitialized()) {
            result.error("SDK_NOT_INITIALIZED", "Call initialize() first", null)
            return
        }

        try {
            when (call.method) {
                "initialize" -> {
                    val args = call.arguments<Map<String, Any>>()
                        ?: return result.error("INVALID_ARGUMENT", "Arguments required", null)

                    val username = args["username"] as? String ?: ""
                    val host = args["host"] as? String ?: ""

                    if (username.isBlank()) {
                        return result.error("INVALID_ARGUMENT", "username must not be blank", null)
                    }
                    if (host.isBlank()) {
                        return result.error("INVALID_ARGUMENT", "host must not be blank", null)
                    }

                    BareSipSdk.initialize(applicationContext, args.toSdkConfig())
                    result.success(null)
                }

                "login"     -> { BareSipSdk.login();    result.success(null) }
                "logout"    -> { BareSipSdk.logout();   result.success(null) }
                "goOnline"  -> { BareSipSdk.goOnline(); result.success(null) }
                "goOffline" -> { BareSipSdk.goOffline(); result.success(null) }
                "shutdown"  -> { BareSipSdk.shutdown(); result.success(null) }

                "startCall" -> {
                    val peerUri = call.argument<String>("peerUri")
                    if (peerUri.isNullOrBlank()) {
                        return result.error("INVALID_ARGUMENT", "peerUri required", null)
                    }
                    CallManager.startCall(peerUri)
                    result.success(null)
                }

                "answerCall" -> { CallManager.answerCall(); result.success(null) }
                "rejectCall" -> { CallManager.rejectCall(); result.success(null) }
                "hangup"     -> { CallManager.hangup();     result.success(null) }

                "mute" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    CallManager.mute(muted)
                    result.success(null)
                }

                "hold" -> {
                    val hold = call.argument<Boolean>("hold") ?: false
                    CallManager.hold(hold)
                    result.success(null)
                }

                "setAudioRoute" -> {
                    val routeStr = call.argument<String>("route")
                        ?: return result.error("INVALID_ARGUMENT", "route required", null)
                    val route = try {
                        AudioRoute.valueOf(routeStr)
                    } catch (e: IllegalArgumentException) {
                        return result.error("INVALID_ARGUMENT", "Unknown audio route: $routeStr", null)
                    }
                    SdkAudioManager.setRoute(route)
                    result.success(null)
                }

                "getAvailableRoutes" -> {
                    result.success(SdkAudioManager.getAvailableRoutes().map { it.name })
                }

                "getCurrentRoute" -> {
                    result.success(SdkAudioManager.getCurrentRoute().name)
                }

                "getMissingPermissions" -> {
                    result.success(PermissionManager.getMissingPermissions(applicationContext))
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("SDK_ERROR", e.message ?: "Unknown SDK error", null)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun Map<String, Any>.toSdkConfig(): SdkConfig = SdkConfig(
        username    = this["username"]    as? String ?: "",
        password    = this["password"]    as? String ?: "",
        displayName = this["displayName"] as? String ?: "",
        host        = this["host"]        as? String ?: "",
        port        = (this["port"]       as? Int)    ?: 5060,
        transport   = this["transport"]   as? String ?: "tcp",
        audioCodecs = (this["audioCodecs"] as? List<String>) ?: listOf("PCMU", "PCMA", "opus", "G722"),
        stunServer  = this["stunServer"]  as? String ?: "",
        logLevel    = (this["logLevel"]   as? Int)    ?: 2
    )
}
