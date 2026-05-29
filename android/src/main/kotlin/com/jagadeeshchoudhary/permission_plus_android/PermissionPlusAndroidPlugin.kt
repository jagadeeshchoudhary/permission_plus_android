package com.jagadeeshchoudhary.permission_plus_android

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

/** PermissionPlusAndroidPlugin */
class PermissionPlusAndroidPlugin :
    FlutterPlugin,
    ActivityAware,
    PermissionPlusHostApi,
    PluginRegistry.RequestPermissionsResultListener {

    private var context: Context? = null
    private var activity: Activity? = null

    /// Tracks pending permission-request callbacks keyed by request code.
    private var pendingRequestCallback: ((Result<Unit>) -> Unit)? = null
    private var pendingPermissions: List<String>? = null
    private var requestCode = 0

    // ── FlutterPlugin ────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        PermissionPlusHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
        PermissionPlusHostApi.setUp(binding.binaryMessenger, null)
    }

    // ── ActivityAware ────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // ── PermissionPlusHostApi implementation ─────────────────────────────

    override fun checkPermission(
        permission: PermissionTypeMessage,
        callback: (Result<PermissionStatusMessage>) -> Unit
    ) {
        val ctx = context
        if (ctx == null) {
            callback(Result.failure(FlutterError("no_context", "Context is not available")))
            return
        }
        val androidPermissions = permission.toAndroidPermissions()
        if (androidPermissions.isEmpty()) {
            // Permission not applicable on Android — treat as granted.
            callback(Result.success(PermissionStatusMessage.GRANTED))
            return
        }
        val status = determineStatus(ctx, activity, androidPermissions)
        callback(Result.success(status))
    }

    override fun requestPermission(
        permission: PermissionTypeMessage,
        callback: (Result<PermissionStatusMessage>) -> Unit
    ) {
        val act = activity
        if (act == null) {
            callback(Result.failure(FlutterError("no_activity", "Activity is not available")))
            return
        }
        val androidPermissions = permission.toAndroidPermissions()
        if (androidPermissions.isEmpty()) {
            callback(Result.success(PermissionStatusMessage.GRANTED))
            return
        }
        // Check if already granted.
        if (androidPermissions.all {
                ContextCompat.checkSelfPermission(act, it) == PackageManager.PERMISSION_GRANTED
            }) {
            callback(Result.success(PermissionStatusMessage.GRANTED))
            return
        }
        requestCode++
        pendingPermissions = androidPermissions
        pendingRequestCallback = { result ->
            result.fold(
                onSuccess = {
                    val status = determineStatus(act, act, androidPermissions)
                    callback(Result.success(status))
                },
                onFailure = { callback(Result.failure(it)) }
            )
        }
        ActivityCompat.requestPermissions(act, androidPermissions.toTypedArray(), requestCode)
    }

    override fun requestPermissions(
        permissions: List<PermissionTypeMessage>,
        callback: (Result<List<PermissionStatusMapEntry>>) -> Unit
    ) {
        val act = activity
        if (act == null) {
            callback(Result.failure(FlutterError("no_activity", "Activity is not available")))
            return
        }

        // Collect all Android permissions to request.
        val allAndroid = mutableListOf<String>()
        val permissionMap = mutableMapOf<PermissionTypeMessage, List<String>>()
        for (perm in permissions) {
            val androidPerms = perm.toAndroidPermissions()
            permissionMap[perm] = androidPerms
            for (ap in androidPerms) {
                if (ContextCompat.checkSelfPermission(act, ap) != PackageManager.PERMISSION_GRANTED) {
                    allAndroid.add(ap)
                }
            }
        }

        if (allAndroid.isEmpty()) {
            // All already granted.
            val entries = permissions.map { perm ->
                PermissionStatusMapEntry(
                    permission = perm,
                    status = PermissionStatusMessage.GRANTED,
                )
            }
            callback(Result.success(entries))
            return
        }

        requestCode++
        pendingPermissions = allAndroid.distinct()
        pendingRequestCallback = { result ->
            result.fold(
                onSuccess = {
                    val entries = permissions.map { perm ->
                        val androidPerms = permissionMap[perm] ?: emptyList()
                        val status = if (androidPerms.isEmpty()) {
                            PermissionStatusMessage.GRANTED
                        } else {
                            determineStatus(act, act, androidPerms)
                        }
                        PermissionStatusMapEntry(permission = perm, status = status)
                    }
                    callback(Result.success(entries))
                },
                onFailure = { callback(Result.failure(it)) }
            )
        }
        ActivityCompat.requestPermissions(act, allAndroid.distinct().toTypedArray(), requestCode)
    }

    override fun openSettings(callback: (Result<Boolean>) -> Unit) {
        val ctx = context
        if (ctx == null) {
            callback(Result.failure(FlutterError("no_context", "Context is not available")))
            return
        }
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", ctx.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            ctx.startActivity(intent)
            callback(Result.success(true))
        } catch (e: Exception) {
            callback(Result.success(false))
        }
    }

    override fun shouldShowRationale(
        permission: PermissionTypeMessage,
        callback: (Result<Boolean>) -> Unit
    ) {
        val act = activity
        if (act == null) {
            callback(Result.success(false))
            return
        }
        val androidPermissions = permission.toAndroidPermissions()
        val shouldShow = androidPermissions.any {
            ActivityCompat.shouldShowRequestPermissionRationale(act, it)
        }
        callback(Result.success(shouldShow))
    }

    override fun getLocationAccuracy(callback: (Result<LocationAccuracyMessage>) -> Unit) {
        val ctx = context
        if (ctx == null) {
            callback(Result.failure(FlutterError("no_context", "Context is not available")))
            return
        }
        val hasFine = ContextCompat.checkSelfPermission(
            ctx, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        callback(
            Result.success(
                if (hasFine) LocationAccuracyMessage.PRECISE
                else LocationAccuracyMessage.REDUCED
            )
        )
    }

    override fun requestTemporaryPreciseLocation(
        purposeKey: String,
        callback: (Result<PermissionStatusMessage>) -> Unit
    ) {
        // Android does not have the concept of temporary precise location like iOS.
        // Return the current location permission status.
        val ctx = context
        if (ctx == null) {
            callback(Result.failure(FlutterError("no_context", "Context is not available")))
            return
        }
        val locationPerms = listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        val status = determineStatus(ctx, activity, locationPerms)
        callback(Result.success(status))
    }

    // ── RequestPermissionsResultListener ─────────────────────────────────

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == this.requestCode && pendingRequestCallback != null) {
            pendingRequestCallback?.invoke(Result.success(Unit))
            pendingRequestCallback = null
            pendingPermissions = null
            return true
        }
        return false
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    /**
     * Determines the [PermissionStatusMessage] for a set of Android permissions.
     *
     * Checks grant state, rationale flag, and shared-prefs "was requested" flag
     * to distinguish between denied, permanently denied, and not determined.
     */
    private fun determineStatus(
        context: Context,
        activity: Activity?,
        androidPermissions: List<String>
    ): PermissionStatusMessage {
        val allGranted = androidPermissions.all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
        if (allGranted) return PermissionStatusMessage.GRANTED

        // If any permission should show rationale, it's "denied" (not permanently).
        if (activity != null) {
            val anyShowRationale = androidPermissions.any {
                ActivityCompat.shouldShowRequestPermissionRationale(activity, it)
            }
            if (anyShowRationale) return PermissionStatusMessage.DENIED

            // Check if we've requested before. If yes and no rationale → permanently denied.
            val prefs = context.getSharedPreferences("permission_plus_prefs", Context.MODE_PRIVATE)
            val wasRequested = androidPermissions.any { prefs.getBoolean(it, false) }
            if (wasRequested) return PermissionStatusMessage.PERMANENTLY_DENIED

            // Mark as requested for future checks.
            prefs.edit().apply {
                androidPermissions.forEach { putBoolean(it, true) }
                apply()
            }
        }

        return PermissionStatusMessage.NOT_DETERMINED
    }
}

// ── Permission type → Android manifest permission mapping ───────────────

/**
 * Maps a Pigeon [PermissionTypeMessage] to the corresponding Android
 * manifest permission string(s).
 *
 * Returns an empty list for permissions that don't apply on Android.
 */
fun PermissionTypeMessage.toAndroidPermissions(): List<String> {
    return when (this) {
        PermissionTypeMessage.CAMERA -> listOf(Manifest.permission.CAMERA)
        PermissionTypeMessage.MICROPHONE -> listOf(Manifest.permission.RECORD_AUDIO)

        PermissionTypeMessage.PHOTOS -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                listOf(Manifest.permission.READ_MEDIA_IMAGES)
            } else {
                listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
        }
        PermissionTypeMessage.PHOTOS_ADD_ONLY -> emptyList() // iOS only

        PermissionTypeMessage.LOCATION -> listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        PermissionTypeMessage.LOCATION_ALWAYS -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                listOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            } else {
                listOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                )
            }
        }
        PermissionTypeMessage.LOCATION_WHEN_IN_USE -> listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )

        PermissionTypeMessage.NOTIFICATION -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                listOf(Manifest.permission.POST_NOTIFICATIONS)
            } else {
                emptyList() // Not a runtime permission before Android 13
            }
        }

        PermissionTypeMessage.CONTACTS -> listOf(
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.WRITE_CONTACTS,
        )
        PermissionTypeMessage.CONTACTS_READ_ONLY -> listOf(Manifest.permission.READ_CONTACTS)
        PermissionTypeMessage.CONTACTS_WRITE_ONLY -> listOf(Manifest.permission.WRITE_CONTACTS)

        PermissionTypeMessage.CALENDAR -> listOf(
            Manifest.permission.READ_CALENDAR,
            Manifest.permission.WRITE_CALENDAR,
        )
        PermissionTypeMessage.CALENDAR_READ_ONLY -> listOf(Manifest.permission.READ_CALENDAR)
        PermissionTypeMessage.CALENDAR_WRITE_ONLY -> listOf(Manifest.permission.WRITE_CALENDAR)

        PermissionTypeMessage.REMINDERS -> emptyList() // iOS only

        PermissionTypeMessage.STORAGE -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                emptyList() // Use granular media permissions on Android 13+
            } else {
                listOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                )
            }
        }
        PermissionTypeMessage.STORAGE_READ_ONLY -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                emptyList()
            } else {
                listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
        }
        PermissionTypeMessage.STORAGE_WRITE_ONLY -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                emptyList()
            } else {
                listOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }

        PermissionTypeMessage.BLUETOOTH -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                listOf(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT,
                )
            } else {
                listOf(Manifest.permission.BLUETOOTH)
            }
        }

        PermissionTypeMessage.SPEECH -> listOf(Manifest.permission.RECORD_AUDIO)

        PermissionTypeMessage.MEDIA_LIBRARY -> emptyList() // iOS only

        PermissionTypeMessage.SENSORS -> listOf(Manifest.permission.BODY_SENSORS)

        PermissionTypeMessage.PHONE -> listOf(Manifest.permission.CALL_PHONE)

        PermissionTypeMessage.SMS -> listOf(
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_SMS,
        )

        PermissionTypeMessage.APP_TRACKING_TRANSPARENCY -> emptyList() // iOS only
        PermissionTypeMessage.CRITICAL_ALERTS -> emptyList() // iOS only

        PermissionTypeMessage.VIDEOS -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                listOf(Manifest.permission.READ_MEDIA_VIDEO)
            } else {
                listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
        }
        PermissionTypeMessage.AUDIO -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                listOf(Manifest.permission.READ_MEDIA_AUDIO)
            } else {
                listOf(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
        }
    }
}
