package com.sip.baresip.flutter

import com.sip.baresipsdk.BareSipSdk
import io.flutter.plugin.common.EventChannel

class SdkStreamHandler : EventChannel.StreamHandler {

    var callback: SdkCallbackImpl? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        val cb = SdkCallbackImpl(sink)
        callback = cb
        BareSipSdk.registerCallback(cb)
    }

    override fun onCancel(arguments: Any?) {
        callback?.let { BareSipSdk.unregisterCallback(it) }
        callback = null
    }
}
