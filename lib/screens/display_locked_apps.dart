import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';
import 'package:app_lock_flutter/models/application_model.dart';
import 'package:app_lock_flutter/services/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:installed_apps/app_info.dart';
import 'package:lottie/lottie.dart';

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
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: size.width,
            child: GetBuilder<AppsController>(
              builder: (appsController) {
                if (appsController.lockList.isEmpty) {
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
                            "Loading...",
                            style: MyFont().subtitle(
                              color: Theme.of(context).primaryColor,
                              fontweight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    return await appsController.getAppsData();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: appsController.lockList.length,
                    itemBuilder: (context, index) {
                      ApplicationDataModel app = appsController.lockList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).primaryColorDark,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                          backgroundImage: MemoryImage(
                                              app.application!.icon!),
                                          backgroundColor: Theme.of(context)
                                              .primaryColorDark,
                                        )
                                      : CircleAvatar(
                                          backgroundColor: Theme.of(context)
                                              .primaryColorDark,
                                          child: Text(
                                            "N/A",
                                            style: MyFont().subtitle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.application!.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(color: Colors.white),
                                      ),
                                      Text(
                                        app.application!.getVersionInfo(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
