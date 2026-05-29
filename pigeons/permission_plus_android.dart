import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'permission_plus_android',
    dartOut: 'lib/src/generated/permission_plus_api.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/jagadeeshchoudhary/permission_plus_android/PermissionPlusApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.jagadeeshchoudhary.permission_plus_android',
    ),
  ),
)

/// Mirror of `PermissionType` from `permission_plus_platform_interface`.
enum PermissionTypeMessage {
  camera,
  microphone,
  photos,
  photosAddOnly,
  location,
  locationAlways,
  locationWhenInUse,
  notification,
  contacts,
  contactsReadOnly,
  contactsWriteOnly,
  calendar,
  calendarReadOnly,
  calendarWriteOnly,
  reminders,
  storage,
  storageReadOnly,
  storageWriteOnly,
  bluetooth,
  speech,
  mediaLibrary,
  sensors,
  phone,
  sms,
  appTrackingTransparency,
  criticalAlerts,
  videos,
  audio,
}

/// Mirror of `PermissionStatus` from `permission_plus_platform_interface`.
enum PermissionStatusMessage {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  provisional,
}

/// Mirror of `LocationAccuracy` from `permission_plus_platform_interface`.
enum LocationAccuracyMessage {
  reduced,
  precise,
}

/// Represents a single entry in a permission → status map.
///
/// Used for returning results from [requestPermissions], since Pigeon
/// does not support `Map` with enum keys directly.
class PermissionStatusMapEntry {
  PermissionStatusMapEntry({
    required this.permission,
    required this.status,
  });

  final PermissionTypeMessage permission;
  final PermissionStatusMessage status;
}

/// Host API implemented in Kotlin, called from Dart.
@HostApi()
abstract class PermissionPlusHostApi {
  /// Checks the current status of [permission] without triggering a request.
  @async
  PermissionStatusMessage checkPermission(PermissionTypeMessage permission);

  /// Requests [permission] from the user.
  @async
  PermissionStatusMessage requestPermission(PermissionTypeMessage permission);

  /// Requests multiple [permissions] at once.
  @async
  List<PermissionStatusMapEntry> requestPermissions(
    List<PermissionTypeMessage> permissions,
  );

  /// Opens the platform's app settings page.
  @async
  bool openSettings();

  /// Whether the platform recommends showing a rationale before requesting
  /// [permission].
  @async
  bool shouldShowRationale(PermissionTypeMessage permission);

  /// Gets the current location accuracy level.
  @async
  LocationAccuracyMessage getLocationAccuracy();

  /// Requests temporary precise location access.
  ///
  /// On Android this returns the current location permission status.
  @async
  PermissionStatusMessage requestTemporaryPreciseLocation(String purposeKey);
}
