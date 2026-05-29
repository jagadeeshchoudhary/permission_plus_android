import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

import 'src/generated/permission_plus_api.g.dart';

/// Android implementation of [PermissionPlusPlatform].
///
/// Uses Pigeon-generated [PermissionPlusHostApi] for type-safe
/// communication with the Kotlin host.
class PermissionPlusAndroid extends PermissionPlusPlatform {
  PermissionPlusAndroid({@visibleForTesting PermissionPlusHostApi? api})
      : _api = api ?? PermissionPlusHostApi();

  final PermissionPlusHostApi _api;

  /// Registers this class as the default [PermissionPlusPlatform] instance.
  static void registerWith() {
    PermissionPlusPlatform.instance = PermissionPlusAndroid();
  }

  @override
  Future<PermissionStatus> checkPermission(PermissionType permission) async {
    final result = await _api.checkPermission(permission.toPigeon());
    return result.toPlatform();
  }

  @override
  Future<PermissionStatus> requestPermission(PermissionType permission) async {
    final result = await _api.requestPermission(permission.toPigeon());
    return result.toPlatform();
  }

  @override
  Future<Map<PermissionType, PermissionStatus>> requestPermissions(
    List<PermissionType> permissions,
  ) async {
    final entries = await _api.requestPermissions(
      permissions.map((p) => p.toPigeon()).toList(),
    );
    return {
      for (final entry in entries)
        entry.permission.toPlatformType(): entry.status.toPlatform(),
    };
  }

  @override
  Future<bool> openSettings() => _api.openSettings();

  @override
  Future<bool> shouldShowRationale(PermissionType permission) =>
      _api.shouldShowRationale(permission.toPigeon());

  @override
  Future<LocationAccuracy> getLocationAccuracy() async {
    final result = await _api.getLocationAccuracy();
    return result == LocationAccuracyMessage.precise
        ? LocationAccuracy.precise
        : LocationAccuracy.reduced;
  }

  @override
  Future<PermissionStatus> requestTemporaryPreciseLocation({
    required String purposeKey,
  }) async {
    final result = await _api.requestTemporaryPreciseLocation(purposeKey);
    return result.toPlatform();
  }

  @override
  Stream<PermissionStatus> permissionStatusStream(PermissionType permission) {
    throw UnimplementedError(
      'permissionStatusStream() is not implemented on Android.',
    );
  }
}

// ── Enum mapping extensions ─────────────────────────────────────────────

/// Converts platform interface [PermissionType] to Pigeon message enum.
extension _PermissionTypeToPigeon on PermissionType {
  PermissionTypeMessage toPigeon() =>
      PermissionTypeMessage.values[index];
}

/// Converts Pigeon [PermissionTypeMessage] back to platform interface type.
extension _PermissionTypeMessageToPlatform on PermissionTypeMessage {
  PermissionType toPlatformType() =>
      PermissionType.values[index];
}

/// Converts Pigeon [PermissionStatusMessage] to platform interface type.
extension _PermissionStatusMessageToPlatform on PermissionStatusMessage {
  PermissionStatus toPlatform() =>
      PermissionStatus.values[index];
}
