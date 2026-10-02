import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../utils/my_colors.dart';
import '../../utils/config.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';

// import '../home_screen.dart';
// import '../ekycVerificationPage.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String fromScreen; // <-- Add this
  final String userid;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.fromScreen, 
    required this.userid
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>   {
  List<TextEditingController> controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());
  dynamic userData= {};
  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
   @override
  void initState() {
    super.initState();

     var userDataValue = Preferences.getUserDetails();
     if (userDataValue != null && userDataValue.isNotEmpty) {
       try {
         userData = json.decode(userDataValue);
       } catch (_) {
         userData = {};
       }
     }
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  bool get _isOtpComplete {
    return controllers.every((controller) => controller.text.isNotEmpty);
  }

  void callOtpResendAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.resendOtp, {
        "user_id": userData["user_id"],
      }).then((value) async {
        UtilClass.hideProgress();
       
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void callOtpVeifyAPI() async {

    String otp = controllers.map((controller) => controller.text).join();
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.verifyOtp, {
         "user_id": userData["user_id"],
        "otp":otp,
        "token": Preferences.getFcmToken() ?? "testing",
      }).then((value) async {
       UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
             _showSuccessDialog();

          } else {
            // ignore: use_build_context_synchronously
            UtilClass.showAlertDialog(
              // ignore: use_build_context_synchronously
              context: context,
              message: parsed["message"],
            );
          }
        } catch (e) {
          print(e);
        }
        print(parsed["message"]);
       
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/images/greentick.png", width: 60, height: 60),
              const SizedBox(height: 15),
              const Text(
                "OTP Verified Successfully",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.appThemeLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog

                    if (widget.fromScreen == "login") {
                      /// 🔹 Existing provider logging in -> Directly to Dashboard
                      final u = userData is Map ? userData : <String, dynamic>{};
                      final isCustomer = (u["customer"] == "1" || u["customer"] == 1 || u["role"] == "customer" || u["user_type"] == "customer");
                      final isProvider = (u["provider"] == "1" || u["provider"] == 1 || u["role"] == "provider" || u["user_type"] == "provider");
                      final isCustomerOnly = isCustomer && !isProvider;

                      if (isCustomerOnly) {
                        UtilClass.showAlertDialog(
                          context: context,
                          message: "This phone number is registered as a Customer. Please sign up as a GoBuddy Provider.",
                        );
                        return;
                      }

                      Navigator.of(
                        context,
                      ).pushReplacementNamed(Config.dashboardcRouteName);
                    } else if (widget.fromScreen == "register") {
                      /// 🔹 If navigated from Register -> Go to EKYCVerification
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(Config.ekycRouteName);
                    }
                  },
                  child: const Text(
                    "Ok",
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: MyColors.lightGreen,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            /// Top Header
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, right: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Material(
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 18,
                              color: MyColors.appThemeLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 45),
                  const Text(
                    "OTP Verification",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: deviceHeight * 0.03),
                    Image.asset("assets/images/otp.png", width: 180),
                    SizedBox(height: deviceHeight * 0.05),

                    /// OTP Section
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Enter the code we sent to the number',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.phoneNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: MyColors.darkGray,
                              ),
                            ),
                            SizedBox(height: deviceHeight * 0.03),

                            /// OTP Boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(4, (index) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: MyColors.lightGreen2,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: controllers[index].text.isNotEmpty
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: controllers[index],
                                    focusNode: focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) =>
                                        _onChanged(value, index),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: deviceHeight * 0.03),

                            /// Resend OTP
                            GestureDetector(
                              onTap: callOtpResendAPI,
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't receive the OTP? ",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Resend OTP',
                                      style: TextStyle(
                                        color: MyColors.appThemeLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: deviceHeight * 0.07),
                  ],
                ),
              ),
            ),

            /// Verify Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isOtpComplete
                        ? const LinearGradient(
                            colors: [Color(0xFFC8BB47), Color(0xFF25AC2C)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[300]!],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isOtpComplete ? callOtpVeifyAPI : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isOtpComplete
                            ? Colors.white
                            : MyColors.lightGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
