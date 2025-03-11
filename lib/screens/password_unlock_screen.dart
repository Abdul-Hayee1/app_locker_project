// ignore_for_file: use_key_in_widget_constructors

import 'package:app_lock_flutter/executables/controllers/password_controller.dart';
import 'package:app_lock_flutter/screens/home.dart';
import 'package:app_lock_flutter/services/constant.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class PasswordUnlockScreen extends StatelessWidget {
  final PasswordController _passwordController = Get.find<PasswordController>();

  PasswordUnlockScreen();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevent back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_left,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Unlock App",
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
        body: SizedBox(
          height: size.height,
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 10,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/appLogo.png',
                      height: 100,
                      width: 100,
                    ),
                  ),
                ),
              ),
              const Text(
                "Enter your passcode",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              // Display entered passcode (as dots)
              GetBuilder<PasswordController>(
                builder: (controller) {
                  return Text(
                    controller.passcode.split("").map((e) => "•").join(),
                    style: const TextStyle(fontSize: 30, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Numeric keypad
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 25,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 0.0,
                    childAspectRatio: 2,
                    mainAxisSpacing: 10.0,
                  ),
                  itemCount: 12, // 0-9, backspace, and empty
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return const SizedBox.shrink(); // Empty space
                    } else if (index == 10) {
                      return GestureDetector(
                        onTap: () {
                          _passwordController.setPasscode(10); // 0
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColorDark,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              "0",
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    } else if (index == 11) {
                      return GestureDetector(
                        onTap: () {
                          _passwordController.setPasscode(11); // Backspace
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColorDark,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.backspace,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          _passwordController.setPasscode(index); // 1-9
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColorDark,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                  fontSize: 24, color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Submit button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                  child: MaterialButton(
                    color: Colors.transparent,
                    elevation: 0,
                    onPressed: () {
                      // Validate the entered password
                      String savedPassword = _passwordController.prefs
                              .getString(AppConstants.setPassCode) ??
                          "";

                      if (_passwordController.passcode == savedPassword) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      } else {
                        // Show error message for incorrect passcode
                        Fluttertoast.showToast(msg: "Incorrect passcode");

                        // Clear the passcode after incorrect attempt
                        _passwordController.clearPasscode();
                      }
                    },
                    child: const Text(
                      "Unlock",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
