// ignore_for_file: avoid_print, annotate_overrides

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
// import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lock_flutter/executables/controllers/method_channel_controller.dart';
import 'package:app_lock_flutter/services/constant.dart';
import '../../models/application_model.dart';

class NativeChannel {
  static const _channel = MethodChannel('com.example.app_locker/native');

  static Future<void> sendLockList(List<Map<String, dynamic>> lockList) async {
    try {
      await _channel.invokeMethod('updateLockList', lockList);
    } on PlatformException catch (e) {
      print("Failed to send lock list: '${e.message}'.");
    }
  }
}

class AppsController extends GetxController implements GetxService {
  SharedPreferences prefs;
  AppsController({required this.prefs});

  String? dummyPasscode;
  int? selectQuestion;
  TextEditingController typeAnswer = TextEditingController();
  TextEditingController checkAnswer = TextEditingController();
  TextEditingController searchApkText = TextEditingController();
  // List<Application> unLockList = [];    // deprecated one
  List<AppInfo> unLockList = []; // alternate
  List<AppInfo> systemApps = [];
  List<ApplicationDataModel> searchedApps = [];
  List<ApplicationDataModel> lockList = [];
  List<String> selectLockList = [];
  bool addToAppsLoading = false;

  List<String> excludedApps = [
    "com.android.settings",
    "com.example.app_locker",
  ];
  static const eventChannel = EventChannel('com.example.app_locker/events');

  int appSearchUpdate = 1;
  int addRemoveToUnlockUpdate = 2;
  int addRemoveToUnlockUpdateSearch = 3;

  void onInit() {
    super.onInit();
    getAppsData();
    loadLockedApps();
    _listenToEvents();
    updateLockList(lockList);
  }

  void _listenToEvents() {
    eventChannel.receiveBroadcastStream().listen((event) {
      print("Testing AppLocker App opened: $event");
    });
  }

  void updateLockList(List<ApplicationDataModel> lockList) {
    final List<Map<String, dynamic>> lockListData = lockList.map((app) {
      // Print the holdDuration for each app
      print(
          "App: ${app.application!.packageName}, Hold Duration: ${app.holdDuration?.inSeconds ?? 3} seconds");

      return {
        'packageName': app.application!.packageName,
        'isLocked': app.isLocked,
        'holdDuration': app.holdDuration?.inSeconds.toInt() ?? 3,
      };
    }).toList();

    NativeChannel.sendLockList(lockListData);
  }

  changeQuestionIndex(index) {
    selectQuestion = index;
    update();
  }

  resetAskQuetionsPage() {
    selectQuestion = null;
    typeAnswer.clear();
    checkAnswer.clear();
  }

  savePasscode(counter) {
    prefs.setString(AppConstants.setPassCode, counter);
    Get.find<MethodChannelController>().setPassword();
    log("${prefs.getString(AppConstants.setPassCode)}", name: "save passcode");
  }

  getPasscode() {
    return prefs.getString(AppConstants.setPassCode) ?? "";
  }

  removePasscode() {
    return prefs.remove(AppConstants.setPassCode);
  }

  setSplash() {
    prefs.setBool("Splash", true);
    return prefs.getBool("Splash");
  }

  getSplash() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getBool("Splash")) != null) {
      return true;
    } else {
      return false;
    }
  }

  excludeApps() {
    for (var e in excludedApps) {
      unLockList.removeWhere((element) => element.packageName == e);
    }
  }

  Future<void> getAppsData() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);

    unLockList = filterLaunchableApps(apps);
    systemApps = getSystemApps(apps);

    excludeApps();
    loadLockedApps();
    update();
  }

  List<AppInfo> filterLaunchableApps(List<AppInfo> apps) {
    return apps.where((app) => app.packageName.isNotEmpty).toList();
  }

  List<AppInfo> getSystemApps(List<AppInfo> apps) {
    return apps.where((app) {
      return app.packageName.startsWith("com.android") ||
          app.packageName.startsWith("com.google.android");
    }).toList();
  }

  Uint8List? getAppIcon(AppInfo app) {
    return app.icon;
  }

  Future<void> loadLockedApps() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedList = prefs.getStringList(AppConstants.appsKey) ?? [];

    lockList = storedList
        .map((json) => ApplicationDataModel.fromJson(jsonDecode(json)))
        .toList();

    selectLockList =
        lockList.map((app) => app.application!.name).toList(); // Sync names

    updateLockList(lockList);
    update([addRemoveToUnlockUpdate]);
  }

  Future<void> saveLockedApps() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedList =
        lockList.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList(AppConstants.appsKey, storedList);
    log("Saved Locked Apps: $storedList");
  }

  addRemoveFromLockedAppsFromSearch(AppInfo app) {
    addToAppsLoading = true;
    update();
    try {
      if (selectLockList.contains(app.name)) {
        selectLockList.remove(app.name);
        lockList
            .removeWhere((element) => element.application!.name == app.name);
      } else {
        if (lockList.length < 16) {
          selectLockList.add(app.name);
          lockList.add(
            ApplicationDataModel(isLocked: true, application: app),
          );
        } else {
          Fluttertoast.showToast(
              msg: "You can add only 16 apps in locked list");
        }
      }
      updateLockList(lockList);
    } catch (e) {
      log("-------$e", name: "addRemoveFromLockedAppsFromSearch");
    }
    addToAppsLoading = false;
    update();
  }

  addToLockedApps(AppInfo app, context, Duration duration) async {
    addToAppsLoading = true;
    update([addRemoveToUnlockUpdate]);
    print("Starting addToLockedApps...");

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      print("SharedPreferences loaded.");

      List<String> storedList = prefs.getStringList(AppConstants.appsKey) ?? [];
      print("Stored list fetched: $storedList");

      if (selectLockList.contains(app.name)) {
        print("App ${app.name} found in locked list, removing...");

        // If app exists, remove it
        selectLockList.remove(app.name);
        lockList.removeWhere((em) => em.application!.name == app.name);
        storedList.removeWhere((json) {
          final decoded = jsonDecode(json);
          return decoded["application"]["name"] == app.name;
        });

        print("Test Locked apps REMOVE: $selectLockList");
      } else {
        print("App ${app.name} not found, adding...");

        if (lockList.length < 16) {
          // If not in list, add it
          selectLockList.add(app.name);
          ApplicationDataModel newApp = ApplicationDataModel(
            isLocked: true,
            application: app,
            holdDuration: duration,
          );
          lockList.add(newApp);

          // Save the new app to SharedPreferences
          storedList.add(jsonEncode(newApp.toJson()));
          print("Test Locked apps ADD: $selectLockList addToLockedApps");

          Get.find<MethodChannelController>().addToLockedAppsMethod();
        } else {
          Fluttertoast.showToast(
              msg: "You can add only 16 apps in the locked list");
          print("Cannot add more apps. Locked list limit reached.");
        }
      }

      await saveLockedApps();
      print("Locked apps saved to SharedPreferences.");
      updateLockList(lockList);
    } catch (e) {
      log("-------$e", name: "addToLockedApps");
      print("Error encountered: $e");
    }

    addToAppsLoading = false;
    update([addRemoveToUnlockUpdate]);
    print("Finished addToLockedApps.");
  }

  // Future<void> handleAppLaunch(AppInfo app) async {
  //   if (selectLockList.contains(app.name)) {
  //     // Show lock screen if app is locked
  //     showLockScreen(app.packageName);
  //   } else {
  //     // Otherwise, launch the app normally
  //     InstalledApps.startApp(app.packageName);
  //   }
  // }

  // void showLockScreen(String packageName) {
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text("App Locked"),
  //       content: const Text("This app is locked. Enter passcode to continue."),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Get.back(); // Close the lock screen
  //           },
  //           child: const Text("Unlock"),
  //         )
  //       ],
  //     ),
  //     barrierDismissible: false,
  //   );
  // }

  appSearch() {
    searchedApps.clear();
    if (searchApkText.text.length > 2) {
      for (var e in unLockList) {
        if (e.name
            .toUpperCase()
            .contains(searchApkText.text.toUpperCase().trim())) {
          searchedApps.add(
            ApplicationDataModel(isLocked: null, application: e),
          );
        }
      }
      update([appSearchUpdate]);
    }
  }
}
