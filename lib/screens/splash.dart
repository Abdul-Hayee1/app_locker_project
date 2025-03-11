import 'package:app_lock_flutter/screens/password_unlock_screen.dart';
import 'package:app_lock_flutter/services/constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_lock_flutter/screens/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? passcode = prefs.getString(AppConstants.setPassCode);

    Future.delayed(const Duration(seconds: 1), () {
      if (passcode != null && passcode.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PasswordUnlockScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/appLogo.png",
              height: 150,
              width: 150,
            ),
            const SizedBox(height: 150),
            Text(
              "AppLock".toUpperCase(),
              style: GoogleFonts.ubuntu(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
