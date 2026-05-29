import 'package:flutter/material.dart';
import 'dart:async';

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
  String _status = 'Unknown';
  final _plugin = PermissionPlusAndroid();

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    try {
      final status = await _plugin.checkPermission(PermissionType.camera);
      if (!mounted) return;
      setState(() {
        _status = 'Camera permission: ${status.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Permission Plus Example')),
        body: Center(child: Text(_status)),
      ),
    );
  }
}
