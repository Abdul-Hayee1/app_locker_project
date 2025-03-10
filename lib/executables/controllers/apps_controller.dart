import 'dart:developer';
import 'dart:typed_data';
// import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_lock_flutter/executables/controllers/method_channel_controller.dart';
import 'package:app_lock_flutter/services/constant.dart';
import '../../models/application_model.dart';

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

  List<String> excludedApps = ["com.android.settings"];

  int appSearchUpdate = 1;
  int addRemoveToUnlockUpdate = 2;
  int addRemoveToUnlockUpdateSearch = 3;

  void onInit() {
    super.onInit();
    getAppsData();
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

  // Fetch installed apps and filter them
  Future<void> getAppsData() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);

    unLockList = filterLaunchableApps(apps);
    systemApps = getSystemApps(apps);

    excludeApps();
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
            ApplicationDataModel(isLocked: true, application: app
                // application: ApplicationData(
                //   apkFilePath: app.apkFilePath,
                //   appName: app.appName,
                //   category: app.category,
                //   dataDir: app.dataDir,
                //   enabled: app.enabled,
                //   icon: getAppIcon(app.appName as AppInfo),
                //   installTimeMillis: app.installTimeMillis,
                //   packageName: app.packageName,
                //   systemApp: app.systemApp,
                //   updateTimeMillis: app.updateTimeMillis,
                //   versionCode: app.versionCode,
                //   versionName: app.versionName,
                ),
          );
        } else {
          Fluttertoast.showToast(
              msg: "You can add only 16 apps in locked list");
        }
      }
    } catch (e) {
      log("-------$e", name: "addRemoveFromLockedAppsFromSearch");
    }
    addToAppsLoading = false;
    update();
  }

  addToLockedApps(AppInfo app, context, Duration duration) async {
    addToAppsLoading = true;
    update([addRemoveToUnlockUpdate]);
    try {
      if (selectLockList.contains(app.name)) {
        selectLockList.remove(app.name);
        lockList.removeWhere((em) => em.application!.name == app.name);
        log("REMOVE: $selectLockList");
      } else {
        if (lockList.length < 16) {
          selectLockList.add(app.name);
          lockList.add(
            ApplicationDataModel(isLocked: true, application: app
                // application: ApplicationData(
                //   apkFilePath: app.apkFilePath,
                //   appName: app.appName,
                //   category: "${app.category}",
                //   dataDir: "${app.dataDir}",
                //   enabled: app.enabled,
                //   icon: getAppIcon(app.appName as AppInfo),
                //   installTimeMillis: app.installTimeMillis,
                //   packageName: app.packageName,
                //   systemApp: app.systemApp,
                //   updateTimeMillis: app.updateTimeMillis,
                //   versionCode: app.versionCode,
                //   versionName: app.versionName,
                // ),
                ),
          );
          log("ADD: $selectLockList", name: "addToLockedApps");
          Get.find<MethodChannelController>().addToLockedAppsMethod();
        } else {
          Fluttertoast.showToast(
              msg: "You can add only 16 apps in locked list");
        }
      }
    } catch (e) {
      log("-------$e", name: "addToLockedApps");
    }
    prefs.setString(
        AppConstants.lockedApps, applicationDataModelToJson(lockList));
    addToAppsLoading = false;
    update([addRemoveToUnlockUpdate]);
  }

  getLockedApps() {
    try {
      lockList = applicationDataModelFromJson(
          prefs.getString(AppConstants.lockedApps) ?? '');
      selectLockList.clear();
      log('${lockList.length}', name: "STORED LIST");
      for (var e in lockList) {
        selectLockList.add(e.application!.name);
      }
      log('${lockList.length}-$selectLockList', name: "Locked Apps");
    } catch (e) {
      log("-------$e", name: "getLockedApps");
    }

    update();
  }

  // android manifest bhi theek krni hai permissions according to old provided project (self reminder)

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
