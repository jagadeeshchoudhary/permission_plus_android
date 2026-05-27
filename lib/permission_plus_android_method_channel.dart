import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'permission_plus_android_platform_interface.dart';

/// An implementation of [PermissionPlusAndroidPlatform] that uses method channels.
class MethodChannelPermissionPlusAndroid extends PermissionPlusAndroidPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('permission_plus_android');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
