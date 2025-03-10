import 'package:app_lock_flutter/models/application_model.dart';
import 'package:flutter/material.dart';
import 'package:app_lock_flutter/executables/controllers/apps_controller.dart';
import 'package:get/get.dart';
import 'package:installed_apps/app_info.dart';

void voidAddToLockedAppsModalSheet(BuildContext context, AppInfo app) {
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
      return _AddToLockedListModal(app);
    },
  );
}

class _AddToLockedListModal extends StatefulWidget {
  final AppInfo app;

  const _AddToLockedListModal(this.app, {Key? key}) : super(key: key);

  @override
  State<_AddToLockedListModal> createState() => _AddToLockedListModalState();
}

class _AddToLockedListModalState extends State<_AddToLockedListModal> {
  int durationInSeconds = 7; // Default value

  void increaseDuration() {
    setState(() {
      durationInSeconds += 1;
    });
  }

  void decreaseDuration() {
    setState(() {
      if (durationInSeconds > 1) {
        durationInSeconds -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Add to Locked Apps',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Divider(thickness: 0.5, color: Colors.grey[700]),

          // Duration Setter
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set duration:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: decreaseDuration,
                    ),
                    Text(
                      '$durationInSeconds sec',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: increaseDuration,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 50),

          ElevatedButton(
            onPressed: () {
              final appsController = Get.find<AppsController>();
              appsController.addToLockedApps(
                  widget.app, context, Duration(seconds: durationInSeconds));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Add',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
