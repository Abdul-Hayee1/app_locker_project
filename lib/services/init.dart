// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';

import '../executables/controllers/home_screen_controller.dart';
import '../executables/controllers/method_channel_controller.dart';
import '../executables/controllers/password_controller.dart';
import '../executables/controllers/permission_controller.dart';

Future<void> initialize() async {
  final prefs = await SharedPreferences.getInstance();
  // FlutterForegroundTask.init(
  //   androidNotificationOptions: AndroidNotificationOptions(
  //     channelId: 'foreground_service',
  //     channelName: 'Foreground Service',
  //     channelDescription:
  //         'This notification appears when the foreground service is running.',
  //     channelImportance: NotificationChannelImportance.LOW,
  //     priority: NotificationPriority.LOW,
  //   ),
  //   iosNotificationOptions: IOSNotificationOptions(),
  //   foregroundTaskOptions: ForegroundTaskOptions(
  //     eventAction: ForegroundTaskEventAction.repeat(5000),
  //     autoRunOnBoot: true,
  //     allowWakeLock: true,
  //   ),
  // );
  Get.lazyPut(() => prefs);
  Get.lazyPut(() => AppsController(prefs: Get.find()));
  Get.lazyPut(() => HomeScreenController(prefs: Get.find()));
  Get.lazyPut(() => MethodChannelController());
  Get.lazyPut(() => PermissionController());
  Get.lazyPut(() => PasswordController(prefs: Get.find()));
}
