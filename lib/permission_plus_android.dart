
import 'permission_plus_android_platform_interface.dart';

class PermissionPlusAndroid {
  Future<String?> getPlatformVersion() {
    return PermissionPlusAndroidPlatform.instance.getPlatformVersion();
  }
}
