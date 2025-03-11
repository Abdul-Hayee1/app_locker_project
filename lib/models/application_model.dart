import 'dart:convert';
import 'package:installed_apps/app_info.dart';

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
                builtWith: _parseBuiltWith(json["application"]["builtWith"]),
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
                "builtWith": _encodeBuiltWith(application!.builtWith),
                "installedTimestamp": application!.installedTimestamp,
              }
            : null,
        "holdDuration": holdDuration?.inSeconds,
      };

  static BuiltWith _parseBuiltWith(String? builtWithRaw) {
    if (builtWithRaw == "flutter") {
      return BuiltWith.flutter;
    } else if (builtWithRaw == "react_native") {
      return BuiltWith.react_native;
    } else if (builtWithRaw == "xamarin") {
      return BuiltWith.xamarin;
    } else if (builtWithRaw == "ionic") {
      return BuiltWith.ionic;
    }
    return BuiltWith.native_or_others;
  }

  static String _encodeBuiltWith(BuiltWith builtWith) {
    switch (builtWith) {
      case BuiltWith.flutter:
        return "flutter";
      case BuiltWith.react_native:
        return "react_native";
      case BuiltWith.xamarin:
        return "xamarin";
      case BuiltWith.ionic:
        return "ionic";
      case BuiltWith.native_or_others:
        return "native_or_others";
    }
  }
}
