import 'package:flutter_test/flutter_test.dart';
import 'package:permission_plus_android/permission_plus_android.dart';
import 'package:permission_plus_android/src/generated/permission_plus_api.g.dart';
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

/// A fake implementation of [PermissionPlusHostApi] for unit testing.
class FakePermissionPlusHostApi extends PermissionPlusHostApi {
  @override
  Future<PermissionStatusMessage> checkPermission(
    PermissionTypeMessage permission,
  ) async {
    return PermissionStatusMessage.granted;
  }

  @override
  Future<PermissionStatusMessage> requestPermission(
    PermissionTypeMessage permission,
  ) async {
    return PermissionStatusMessage.granted;
  }

  @override
  Future<List<PermissionStatusMapEntry>> requestPermissions(
    List<PermissionTypeMessage> permissions,
  ) async {
    return permissions
        .map(
          (p) => PermissionStatusMapEntry(
            permission: p,
            status: PermissionStatusMessage.granted,
          ),
        )
        .toList();
  }

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> shouldShowRationale(PermissionTypeMessage permission) async =>
      false;

  @override
  Future<LocationAccuracyMessage> getLocationAccuracy() async =>
      LocationAccuracyMessage.precise;

  @override
  Future<PermissionStatusMessage> requestTemporaryPreciseLocation(
    String purposeKey,
  ) async {
    return PermissionStatusMessage.granted;
  }
}

void main() {
  late PermissionPlusAndroid plugin;
  late FakePermissionPlusHostApi fakeApi;

  setUp(() {
    fakeApi = FakePermissionPlusHostApi();
    plugin = PermissionPlusAndroid(api: fakeApi);
  });

  test('checkPermission returns granted', () async {
    final status = await plugin.checkPermission(PermissionType.camera);
    expect(status, PermissionStatus.granted);
  });

  test('requestPermission returns granted', () async {
    final status = await plugin.requestPermission(PermissionType.camera);
    expect(status, PermissionStatus.granted);
  });

  test('requestPermissions returns map of granted', () async {
    final result = await plugin.requestPermissions([
      PermissionType.camera,
      PermissionType.microphone,
    ]);
    expect(result[PermissionType.camera], PermissionStatus.granted);
    expect(result[PermissionType.microphone], PermissionStatus.granted);
  });

  test('openSettings returns true', () async {
    final result = await plugin.openSettings();
    expect(result, true);
  });

  test('shouldShowRationale returns false', () async {
    final result = await plugin.shouldShowRationale(PermissionType.camera);
    expect(result, false);
  });

  test('getLocationAccuracy returns precise', () async {
    final result = await plugin.getLocationAccuracy();
    expect(result, LocationAccuracy.precise);
  });

  test('requestTemporaryPreciseLocation returns granted', () async {
    final result = await plugin.requestTemporaryPreciseLocation(
      purposeKey: 'test',
    );
    expect(result, PermissionStatus.granted);
  });
}
