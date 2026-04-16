package com.sip.baresip.flutter

import com.sip.baresipsdk.BareSipSdk
import com.sip.baresipsdk.RegistrationState
import io.flutter.plugin.common.EventChannel

class SdkStreamHandler : EventChannel.StreamHandler {

    var callback: SdkCallbackImpl? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        val cb = SdkCallbackImpl(sink)
        callback = cb
        BareSipSdk.registerCallback(cb)

        // When the Flutter engine re-attaches (app relaunch into a running service),
        // the SDK is already registered but the Dart side has no state.
        // Re-deliver the current registration state immediately so the UI syncs.
        val currentRegState = BareSipSdk.registrationState.value
        if (currentRegState != RegistrationState.OFFLINE) {
            sink.success(
                mapOf(
                    "type"   to "registrationState",
                    "state"  to currentRegState.name,
                    "reason" to ""
                )
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        callback?.let { BareSipSdk.unregisterCallback(it) }
        callback = null
    }
}
