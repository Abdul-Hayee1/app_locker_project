// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:app_lock_flutter/models/application_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_lock_flutter/executables/controllers/method_channel_controller.dart';
import 'package:app_lock_flutter/executables/controllers/permission_controller.dart';
import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';
import 'package:app_lock_flutter/screens/unlocked_apps.dart';
import 'package:app_lock_flutter/widgets/ask_permission_dialog.dart';

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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const serviceChannel = MethodChannel('com.example.app_locker/service');
  static const accessibilityChannel =
      MethodChannel('com.example.app_locker/accessibility');

  final AppLockerService _appLockerService = AppLockerService();
  bool _isAccessibilityEnabled = false;

  Future<void> _startService() async {
    print("Starting service...");

    try {
      await serviceChannel.invokeMethod('startService');
      print("Service started successfully.");
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
    }
  }

  Future<void> _stopService() async {
    print("Stopping service...");

    try {
      await serviceChannel.invokeMethod('stopService');
      print("Service stopped successfully.");
    } on PlatformException catch (e) {
      print("Failed to stop service: '${e.message}'.");
    }
  }

  void _checkIfAppIsLocked(String packageName) {
    print("Checking if app is locked for package: $packageName");

    final lockList = Get.find<AppsController>().lockList;
    final lockedApp = lockList.firstWhere(
      (app) => app.application!.packageName == packageName,
      orElse: () => ApplicationDataModel(),
    );

    if (lockedApp.isLocked == true) {
      print("App is locked. Showing lock screen...");
      _showLockScreen(lockedApp.holdDuration ?? const Duration(seconds: 3));
    } else {
      print("App is not locked.");
    }
  }

  void _showLockScreen(Duration duration) async {
    try {
      await serviceChannel.invokeMethod(
        'showLockScreen',
        {'duration': duration.inSeconds.toInt()},
      );
      print("Value check: ${duration.inSeconds.toInt()}");
    } on PlatformException catch (e) {
      print("Failed to show lock screen: '${e.message}'.");
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
    WidgetsBinding.instance.addObserver(this);
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
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Stop Service"),
                              content: const Text(
                                  "Are you sure you want to stop the service?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await _stopService();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Stop",
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _requestAccessibilityServicePermission();
                      },
                      child: const Text(
                        'Enable Accessibility Service',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_isAccessibilityEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).primaryColorDark,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Stop Service"),
                              content: const Text(
                                  "Are you sure you want to stop the service?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await _stopService();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Stop",
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: Icon(
                        Icons.stop_circle_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Accessibility Service is Enabled',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ),
                ],
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
