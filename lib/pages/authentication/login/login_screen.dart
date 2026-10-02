import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for input formatters
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import '../../../utils/my_colors.dart';
import '../../../utils/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();

  String? _errorMessage; // to store error message

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneFocus.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Function that validates phone number when button clicked
  void _validateAndSubmit() {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = "Phone number cannot be empty";
      });
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      setState(() {
        _errorMessage = "Please enter a valid 10-digit phone number";
      });
    } else {
      setState(() {
        _errorMessage = null; // clear error if valid
      });
      print("✅ Phone number entered: $phone");
      // 👉 Here you can navigate to OTP screen if needed
      callOtpVeifyAPI();
    }
  }

  void callOtpVeifyAPI() async {
    String phoneNumber = _phoneController.text.trim();
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.providerLoginApi, {
        "phone_number": phoneNumber,
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            Preferences.setUserDetails(value);

            Navigator.pushNamed(
              // ignore: use_build_context_synchronously
              context,
              Config.otpRouteName,
              arguments: {
                "phone": phoneNumber,
                "user_id": parsed["user_id"],
                "fromScreen": "login",
              },
            );
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.02),

                /// Back button
                // Align(
                //   alignment: Alignment.centerLeft,
                //   child: InkWell(
                //     onTap: () => Navigator.pop(context),
                //     child: Container(
                //       height: screenHeight * 0.055,
                //       width: screenHeight * 0.055,
                //       decoration: BoxDecoration(
                //         gradient: LinearGradient(
                //           colors: [Color(0xFFd4c900), Color(0xFF00ad20)],
                //         ),
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       child: Icon(Icons.arrow_back, color: Colors.white),
                //     ),
                //   ),
                // ),
                SizedBox(height: screenHeight * 0.05),

                /// Logo
                Image.asset(
                  'assets/images/gobuddyIcon.png',
                  height: screenHeight * 0.12,
                ),

                SizedBox(height: screenHeight * 0.01),

                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                Text(
                  "Enter your phone number",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  "We will send you the 4 digit verification code",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                SizedBox(height: screenHeight * 0.04),

                /// Phone field
                _buildTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  label: "Phone Number",
                  prefix: "+91 ",
                  keyboardType: TextInputType.number,
                ),

                /// Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.1),

                /// Button
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.065,
                  child: ElevatedButton(
                    onPressed:
                        _validateAndSubmit, // <-- validation on button click
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFd4c900), Color(0xFF00ad20)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "Get Verification Code",
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                /// Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "New User? ",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black54,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          // ignore: use_build_context_synchronously
                          context,
                          Config.registrationRouteName,
                        );
                      },
                      child: Text(
                        "Register Here",
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable phone number field
Widget _buildTextField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String label,
  String? prefix,
  Widget? suffixIcon,
  TextInputType? keyboardType,
}) {
  bool isFocused = focusNode.hasFocus;
  Color activeColor = MyColors.appThemeLight;
  Color inactiveColor = Colors.grey;

  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType ?? TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly, // only digits allowed
      LengthLimitingTextInputFormatter(10), // max 10 digits
    ],
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 14,
        color: isFocused ? activeColor : inactiveColor,
      ),
      prefixText: prefix,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: MyColors.cardColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: inactiveColor, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: activeColor, width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
