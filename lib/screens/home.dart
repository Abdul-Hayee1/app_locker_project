// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_lock_flutter/executables/controllers/permission_controller.dart';
import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';
import 'package:app_lock_flutter/screens/unlocked_apps.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const serviceChannel = MethodChannel('com.example.app_locker/service');
  static const accessibilityChannel =
      MethodChannel('com.example.app_locker/accessibility');
  static const notificationChannel =
      MethodChannel('com.example.app_locker/notification');

  bool _isDialogVisible = false;

  Future<void> _startService() async {
    print("Starting service...");

    try {
      final areNotificationsGranted = await notificationChannel
          .invokeMethod('areNotificationPermissionsGranted');
      if (areNotificationsGranted) {
        await serviceChannel.invokeMethod('startService');
        print("Service started successfully.");
      } else {
        print("Notification permissions are not granted. Service not started.");
        await _requestNotificationPermission();
      }
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
    }
  }

  Future<void> _requestAccessibilityServicePermission() async {
    try {
      await accessibilityChannel
          .invokeMethod('requestAccessibilityServicePermission');
    } on PlatformException catch (e) {
      print("Failed to open accessibility settings: '${e.message}'.");
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await notificationChannel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      print("Failed to request notification permission: '${e.message}'.");
    }
  }

  Future<void> _checkAccessibilityService() async {
    try {
      final isEnabled = await accessibilityChannel
          .invokeMethod('isAccessibilityServiceEnabled');

      if (!isEnabled && !_isDialogVisible) {
        _showAccessibilityPermissionDialog();
      } else if (isEnabled && _isDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _isDialogVisible = false;
        });
      }
    } on PlatformException catch (e) {
      print("Failed to check accessibility service: '${e.message}'.");
    }
  }

  void _showAccessibilityPermissionDialog() {
    setState(() {
      _isDialogVisible = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Accessibility Service'),
          content: const Text(
              'This app requires accessibility service to be enabled to function properly.'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Not Now',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isDialogVisible = false;
                });
              },
            ),
            TextButton(
              child: const Text(
                'Enable',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isDialogVisible = false;
                });
                await _requestAccessibilityServicePermission();
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogVisible = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Get.find<AppsController>().getAppsData();
      Get.find<AppsController>().loadLockedApps();
      Get.find<PermissionController>()
          .getPermission(Permission.ignoreBatteryOptimizations);
      await _startService(); // Check notification permissions and start service
      _checkAccessibilityService(); // Check accessibility permissions
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccessibilityService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: UnlockedAppScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
