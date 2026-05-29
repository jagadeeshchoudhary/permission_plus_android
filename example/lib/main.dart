import 'package:flutter/material.dart';

import 'package:permission_plus_android/permission_plus_android.dart';
import 'package:permission_plus_platform_interface/permission_plus_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = PermissionPlusAndroid();
  final Map<PermissionType, PermissionStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    for (final permission in PermissionType.values) {
      try {
        final status = await _plugin.checkPermission(permission);
        if (mounted) {
          setState(() {
            _statuses[permission] = status;
          });
        }
      } catch (e) {
        debugPrint('Failed to check permission $permission: $e');
      }
    }
  }

  Future<void> _requestPermission(PermissionType permission) async {
    try {
      final status = await _plugin.requestPermission(permission);
      if (mounted) {
        setState(() {
          _statuses[permission] = status;
        });
      }
    } catch (e) {
      debugPrint('Failed to request permission $permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Permission Plus Example')),
        body: ListView.builder(
          itemCount: PermissionType.values.length,
          itemBuilder: (context, index) {
            final permission = PermissionType.values[index];
            final status = _statuses[permission] ?? PermissionStatus.notDetermined;

            return ListTile(
              title: Text(permission.name),
              subtitle: Text('Status: ${status.name}'),
              trailing: ElevatedButton(
                onPressed: () => _requestPermission(permission),
                child: const Text('Request'),
              ),
            );
          },
        ),
      ),
    );
  }
}
