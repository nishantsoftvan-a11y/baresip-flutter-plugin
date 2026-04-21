package com.sip.baresip.flutter

import android.content.Context
import com.sip.baresipsdk.api.PermissionHelper

object PermissionManager {

    fun getMissingPermissions(context: Context): List<String> {
        return PermissionHelper.checkPermissions(context)
    }

    fun hasAllPermissions(context: Context): Boolean {
        return getMissingPermissions(context).isEmpty()
    }
}
