// ignore_for_file: unused_local_variable, prefer_const_constructors

import 'dart:convert';
// import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';
import 'package:app_lock_flutter/models/application_model.dart';
import 'package:app_lock_flutter/services/constant.dart';
import 'package:flutter/material.dart';
// import 'package:get/get_state_manager/src/simple/get_state.dart';
// import 'package:installed_apps/app_info.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showAppsLockedListModalSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color.fromARGB(255, 36, 38, 63),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return _DisplayAppsLockedListModal();
    },
  );
}

class _DisplayAppsLockedListModal extends StatelessWidget {
  Future<List<ApplicationDataModel>> getStoredLockedApps() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedList = prefs.getStringList(AppConstants.appsKey) ?? [];

    try {
      return storedList
          .map((json) => ApplicationDataModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint("Error decoding locked apps: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return FractionallySizedBox(
      heightFactor: 0.93,
      child: FutureBuilder<List<ApplicationDataModel>>(
        future: getStoredLockedApps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Error in FutureBuilder: ${snapshot.error}");
            return Center(child: Text("Error loading locked apps"));
          }

          List<ApplicationDataModel> lockedApps = snapshot.data ?? [];

          if (lockedApps.isEmpty) {
            return Center(
              child: Container(
                color: Colors.transparent,
                height: 300,
                child: Column(
                  children: [
                    Lottie.asset(
                      "assets/jsonFiles/102600-pink-no-data.json",
                      width: 200,
                    ),
                    Text(
                      "No locked apps",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: lockedApps.length,
            itemBuilder: (context, index) {
              ApplicationDataModel app = lockedApps[index];

              if (app.application == null) {
                return SizedBox(); // Skip null entries
              }

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Theme.of(context).primaryColorDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 20.0,
                              offset: const Offset(5, 5),
                            ),
                          ],
                        ),
                        child: app.application?.icon != null
                            ? CircleAvatar(
                                backgroundImage:
                                    MemoryImage(app.application!.icon!),
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                              )
                            : CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).primaryColorDark,
                                child: Text(
                                  "N/A",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(color: Colors.grey),
                                ),
                              ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.application?.name ?? "Unknown App",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              app.application?.getVersionInfo() ?? "N/A",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
