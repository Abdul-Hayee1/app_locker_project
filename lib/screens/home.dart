// ignore_for_file: avoid_print, use_build_context_synchronously

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
  bool _isDialogVisible = false;

  Future<void> _startService() async {
    print("Starting service...");

    try {
      await serviceChannel.invokeMethod('startService');
      print("Service started successfully.");
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
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
      _showLockScreen(
          lockedApp.holdDuration ?? const Duration(seconds: 3), packageName);
    } else {
      print("App is not locked.");
    }
  }

  void _showLockScreen(Duration duration, String packageName) async {
    try {
      await serviceChannel.invokeMethod(
        'showLockScreen',
        {
          'duration': duration.inSeconds.toInt(),
          'packageName': packageName,
        },
      );
      print("Value check: ${duration.inSeconds.toInt()} for $packageName");
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
      // Recheck accessibility service when the app resumes
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
