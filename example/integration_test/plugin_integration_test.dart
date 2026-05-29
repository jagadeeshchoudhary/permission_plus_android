// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:permission_plus_android/permission_plus_android.dart';
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkPermission returns a valid status',
      (WidgetTester tester) async {
    final PermissionPlusAndroid plugin = PermissionPlusAndroid();
    final PermissionStatus status =
        await plugin.checkPermission(PermissionType.camera);
    // The status depends on the device state, just assert it's a valid enum.
    expect(PermissionStatus.values.contains(status), true);
  });
}
