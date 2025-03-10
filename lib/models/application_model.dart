import 'dart:convert';
import 'dart:typed_data';
import 'package:installed_apps/app_info.dart';

List<ApplicationDataModel> applicationDataModelFromJson(String str) =>
    List<ApplicationDataModel>.from(
        json.decode(str).map((x) => ApplicationDataModel.fromJson(x)));

String applicationDataModelToJson(List<ApplicationDataModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ApplicationDataModel {
  ApplicationDataModel({
    this.isLocked,
    this.application,
    this.holdDuration,
  });

  bool? isLocked;
  AppInfo? application;
  Duration? holdDuration;

  factory ApplicationDataModel.fromJson(Map<String, dynamic> json) =>
      ApplicationDataModel(
        isLocked: json["isLocked"] ?? false,
        application: json["application"] != null
            ? AppInfo(
                name: json["application"]["name"],
                icon: json["application"]["icon"] != null
                    ? base64Decode(json["application"]["icon"])
                    : null,
                packageName: json["application"]["packageName"],
                versionName: json["application"]["versionName"],
                versionCode: json["application"]["versionCode"],
                builtWith: json["application"]["builtWith"],
                installedTimestamp: json["application"]["installedTimestamp"],
              )
            : null,
        holdDuration: json["holdDuration"] != null
            ? Duration(seconds: json["holdDuration"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "isLocked": isLocked,
        "application": application != null
            ? {
                "name": application!.name,
                "icon": application!.icon != null
                    ? base64Encode(application!.icon!)
                    : null,
                "packageName": application!.packageName,
                "versionName": application!.versionName,
                "versionCode": application!.versionCode,
                "builtWith": application!.builtWith,
                "installedTimestamp": application!.installedTimestamp,
              }
            : null,
        "holdDuration": holdDuration?.inSeconds,
      };
}



// class ApplicationData {
//   ApplicationData({
//     required this.appName,
//     this.icon,
//     required this.apkFilePath,
//     required this.packageName,
//     required this.versionName,
//     required this.versionCode,
//     required this.dataDir,
//     required this.systemApp,
//     required this.installTimeMillis,
//     required this.updateTimeMillis,
//     required this.category,
//     required this.enabled,
//   });

//   String appName;
//   Uint8List? icon;
//   String apkFilePath;
//   String packageName;
//   String versionName;
//   int versionCode;
//   String dataDir;
//   bool systemApp;
//   int installTimeMillis;
//   int updateTimeMillis;
//   String category;
//   bool enabled;

//   factory ApplicationData.fromJson(Map<String, dynamic> json) {
//     return ApplicationData(
//       appName: json["appName"] ?? "",
//       icon: json["icon"] != null ? base64Decode(json["icon"]) : null,
//       apkFilePath: json["apkFilePath"] ?? "",
//       packageName: json["packageName"] ?? "",
//       versionName: json["versionName"] ?? "",
//       versionCode: json["versionCode"] ?? 0,
//       dataDir: json["dataDir"] ?? "",
//       systemApp: json["systemApp"] ?? false,
//       installTimeMillis: json["installTimeMillis"] ?? 0,
//       updateTimeMillis: json["updateTimeMillis"] ?? 0,
//       category: json["category"] ?? "Unknown",
//       enabled: json["enabled"] ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         "appName": appName,
//         "icon": icon != null ? base64Encode(icon!) : null,
//         "apkFilePath": apkFilePath,
//         "packageName": packageName,
//         "versionName": versionName,
//         "versionCode": versionCode,
//         "dataDir": dataDir,
//         "systemApp": systemApp,
//         "installTimeMillis": installTimeMillis,
//         "updateTimeMillis": updateTimeMillis,
//         "category": category,
//         "enabled": enabled,
//       };
// }
