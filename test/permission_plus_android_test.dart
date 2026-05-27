import 'package:flutter_test/flutter_test.dart';
import 'package:permission_plus_android/permission_plus_android.dart';
import 'package:permission_plus_android/permission_plus_android_platform_interface.dart';
import 'package:permission_plus_android/permission_plus_android_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPermissionPlusAndroidPlatform
    with MockPlatformInterfaceMixin
    implements PermissionPlusAndroidPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PermissionPlusAndroidPlatform initialPlatform = PermissionPlusAndroidPlatform.instance;

  test('$MethodChannelPermissionPlusAndroid is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPermissionPlusAndroid>());
  });

  test('getPlatformVersion', () async {
    PermissionPlusAndroid permissionPlusAndroidPlugin = PermissionPlusAndroid();
    MockPermissionPlusAndroidPlatform fakePlatform = MockPermissionPlusAndroidPlatform();
    PermissionPlusAndroidPlatform.instance = fakePlatform;

    expect(await permissionPlusAndroidPlugin.getPlatformVersion(), '42');
  });
}
