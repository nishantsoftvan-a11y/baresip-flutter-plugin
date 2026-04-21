package com.sip.baresip.flutter

import com.sip.baresipsdk.model.AudioRoute
import com.sip.baresipsdk.model.CallState
import com.sip.baresipsdk.model.RegistrationState
import com.sip.baresipsdk.api.SdkCallback
import io.flutter.plugin.common.EventChannel

class SdkCallbackImpl(private val sink: EventChannel.EventSink?) : SdkCallback {

    override fun onRegistrationState(state: RegistrationState, reason: String) {
        sink?.success(
            mapOf(
                "type" to "registrationState",
                "state" to state.name,
                "reason" to reason
            )
        )
    }

    override fun onCallState(state: CallState, peerUri: String, callId: Long) {
        sink?.success(
            mapOf(
                "type" to "callState",
                "state" to state.name,
                "peerUri" to peerUri,
                "callId" to callId
            )
        )
    }

    override fun onAudioRouteChanged(route: AudioRoute) {
        sink?.success(
            mapOf(
                "type" to "audioRoute",
                "route" to route.name
            )
        )
    }

    override fun onNetworkState(connected: Boolean) {
        sink?.success(
            mapOf(
                "type" to "networkState",
                "connected" to connected
            )
        )
    }

    override fun onError(code: Int, message: String) {
        sink?.success(
            mapOf(
                "type" to "error",
                "code" to code,
                "message" to message
            )
        )
    }
}
