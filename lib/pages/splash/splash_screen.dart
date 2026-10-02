import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:gobuddy/utils/my_colors.dart';
import 'package:gobuddy/utils/config.dart';
import 'dart:convert';
import 'package:gobuddy/data/preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override

void initState() {
    super.initState();
    startTimer();
  }

  startTimer() {
    var duration = const Duration(
      seconds: 4,
    );
    return Timer(duration, checkConditions);
  }

  checkConditions() {
//  var user = Preferences.getUserDetails();
    // try{
    //   var decoded = json.decode(user!);
    //   final payload = UserL.fromJson(decoded);


    //     Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
    //         MenuScreen()), (Route<dynamic> route) => false);



    // }catch(err){
    //   navigateToLogin();

    // }
    // navigateToonBoard();

    var user = Preferences.getUserDetails();
    try {
      if (user != null && user.trim().isNotEmpty) {
        var decoded = json.decode(user);
        if (decoded != null && (decoded["user_id"] != null || decoded["id"] != null)) {
          navigateToVendorHome();
          return;
        }
      }
      navigateToLogin();
    } catch (err) {
      navigateToLogin();
    }
  }
  //regiFeeRouteName  onBoardRouteName

   void navigateToonBoard() {
    // Navigator.of(context).pushReplacementNamed(
    //   Config.loginRouteName, //loginRouteName dashboardcRouteName
    // );

     Future.delayed(Duration(seconds: 2), () {
            Navigator.pushNamed(
              // ignore: use_build_context_synchronously
              context,
              Config.loginRouteName,
            );
            //RegistrationFeePage
          });

     
  }
 void navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(
      Config.onBoardRouteName,
    );
  }

  void navigateToVendorHome() {
    Navigator.of(context).pushReplacementNamed(
      Config.dashboardcRouteName,
    );

  //  Navigator.pushNamed(context, Config.planSummaryRouteName);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: HexColor(MyColors.white),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Image.asset("assets/images/logo.png"),
          ),
        ),
      ),
    );
  }
}