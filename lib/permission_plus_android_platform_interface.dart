import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'permission_plus_android_method_channel.dart';

abstract class PermissionPlusAndroidPlatform extends PlatformInterface {
  /// Constructs a PermissionPlusAndroidPlatform.
  PermissionPlusAndroidPlatform() : super(token: _token);

  static final Object _token = Object();

  static PermissionPlusAndroidPlatform _instance = MethodChannelPermissionPlusAndroid();

  /// The default instance of [PermissionPlusAndroidPlatform] to use.
  ///
  /// Defaults to [MethodChannelPermissionPlusAndroid].
  static PermissionPlusAndroidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PermissionPlusAndroidPlatform] when
  /// they register themselves.
  static set instance(PermissionPlusAndroidPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
