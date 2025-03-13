// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_lock_flutter/executables/controllers/method_channel_controller.dart';
import 'package:app_lock_flutter/executables/controllers/permission_controller.dart';
import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';
import 'package:app_lock_flutter/screens/unlocked_apps.dart';
import 'package:app_lock_flutter/widgets/ask_permission_dialog.dart';
import 'package:system_alert_window/system_alert_window.dart';

class AppLockerService {
  static const EventChannel _eventChannel =
      EventChannel('com.example.app_locker/events');

  Stream<String> get appUsageStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as String);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const serviceChannel = MethodChannel('com.example.app_locker/service');
  static const accessibilityChannel =
      MethodChannel('com.example.app_locker/accessibility');

  final AppLockerService _appLockerService = AppLockerService();
  bool _isAccessibilityEnabled = false;

  Future<void> _startService() async {
    try {
      await serviceChannel.invokeMethod('startService');
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

  Future<void> _checkAccessibilityService() async {
    try {
      final isEnabled = await accessibilityChannel
          .invokeMethod('isAccessibilityServiceEnabled');
      setState(() {
        _isAccessibilityEnabled = isEnabled;
      });
    } on PlatformException catch (e) {
      print("Failed to check accessibility service: '${e.message}'.");
    }
  }

  getPermissions() async {
    if (!(await Get.find<MethodChannelController>()
            .checkNotificationPermission()) ||
        !(await Get.find<MethodChannelController>().checkOverlayPermission()) ||
        !(await Get.find<MethodChannelController>()
            .checkUsageStatePermission())) {
      Get.find<MethodChannelController>().update();
      askPermissionBottomSheet(context);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Get.find<AppsController>().getAppsData();
      Get.find<AppsController>().loadLockedApps();
      Get.find<PermissionController>()
          .getPermission(Permission.ignoreBatteryOptimizations);
      getPermissions();
      Get.find<MethodChannelController>().addToLockedAppsMethod();
      _startService();
      _checkAccessibilityService();

      _appLockerService.appUsageStream.listen((packageName) {
        _checkIfAppIsLocked(packageName);
      });
    });
  }

  void _checkIfAppIsLocked(String packageName) {
    final lockList = Get.find<AppsController>().lockList;
    final isLocked =
        lockList.any((app) => app.application!.packageName == packageName);
    if (isLocked) {
      _showLockScreen();
    }
  }

  void _showLockScreen() async {
    if (!(await SystemAlertWindow.checkPermissions() ?? false)) {
      await SystemAlertWindow.requestPermissions();
    }

    SystemAlertWindow.showSystemWindow(
      header: SystemWindowHeader(
        title: SystemWindowText(text: "App Locked", fontSize: 16),
      ),
      body: SystemWindowBody(
        rows: [
          EachRow(
            columns: [
              EachColumn(
                text: SystemWindowText(
                  text: "This app is locked. Please unlock to continue.",
                  fontSize: 14,
                  textColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
      footer: SystemWindowFooter(
        buttons: [
          SystemWindowButton(
            text: SystemWindowText(text: "Unlock", fontSize: 14),
            tag: "unlock",
            width: 0,
            height: SystemWindowButton.WRAP_CONTENT,
          ),
        ],
      ),
      margin: SystemWindowMargin(left: 0, right: 0, top: 0, bottom: 0),
      gravity: SystemWindowGravity.TOP,
      width: MediaQuery.of(context).size.width.toInt(),
      height: MediaQuery.of(context).size.height.toInt(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'App Locker',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          if (!_isAccessibilityEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await _requestAccessibilityServicePermission();
                  await _checkAccessibilityService();
                },
                child: const Text(
                  'Enable Accessibility Service',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          if (_isAccessibilityEnabled)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Accessibility Service is Enabled',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ),
          const Expanded(
            child: UnlockedAppScreen(),
          ),
        ],
      ),
    );
  }
}
