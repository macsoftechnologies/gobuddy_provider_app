import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:sms_autofill/sms_autofill.dart';

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

class _OTPVerificationScreenState extends State<OTPVerificationScreen> with CodeAutoFill {
  List<TextEditingController> controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());
  dynamic userData= {};
  bool _isLoading = false;

  @override
  void dispose() {
    try {
      cancel();
      unregisterListener();
    } catch (e) {
      debugPrint("SmsAutoFill dispose error: $e");
    }
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

    _listenForOtp();
  }

  void _listenForOtp() async {
    try {
      listenForCode();
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint("SmsAutoFill listening. App Signature: $signature");
    } catch (e) {
      debugPrint("SmsAutoFill listen error: $e");
    }
  }

  @override
  void codeUpdated() {
    debugPrint("SmsAutoFill codeUpdated received: $code");
    if (code != null && code!.isNotEmpty) {
      final cleanCode = code!.replaceAll(RegExp(r'\D'), '');
      if (cleanCode.length >= 4) {
        for (int i = 0; i < 4; i++) {
          controllers[i].text = cleanCode[i];
        }
        setState(() {});
        if (mounted && _isOtpComplete) {
          FocusScope.of(context).unfocus();
          callOtpVeifyAPI();
        }
      }
    }
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 4) {
        // Multi-digit paste or keyboard autofill
        for (int i = 0; i < 4; i++) {
          controllers[i].text = digits[i];
        }
        setState(() {});
        if (mounted && _isOtpComplete) {
          FocusScope.of(context).unfocus();
          callOtpVeifyAPI();
        }
        return;
      } else if (digits.isNotEmpty) {
        // User typed a new digit into an already-filled box
        final lastDigit = digits[digits.length - 1];
        controllers[index].text = lastDigit;
        controllers[index].selection = TextSelection.fromPosition(
          const TextPosition(offset: 1),
        );
        if (index < 3) {
          focusNodes[index + 1].requestFocus();
        }
        setState(() {});
        if (mounted && _isOtpComplete) {
          FocusScope.of(context).unfocus();
          callOtpVeifyAPI();
        }
        return;
      }
    }

    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    setState(() {});

    if (mounted && _isOtpComplete) {
      FocusScope.of(context).unfocus();
      callOtpVeifyAPI();
    }
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
        // Clear existing input
        for (var c in controllers) {
          c.clear();
        }
        setState(() {});
        if (focusNodes.isNotEmpty) {
          focusNodes[0].requestFocus();
        }
        // Re-listen for the new OTP SMS
        try {
          cancel();
          listenForCode();
        } catch (e) {
          debugPrint("SmsAutoFill re-listen error: $e");
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void callOtpVeifyAPI() async {
    if (_isLoading) return;
    String otp = controllers.map((controller) => controller.text).join();
    if (otp.length < 4) return;

    var internet = await UtilClass.checkInternet();
    if (internet) {
      _isLoading = true;
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      final userIdToSend = (userData is Map && userData["user_id"] != null && userData["user_id"].toString().isNotEmpty)
          ? userData["user_id"].toString()
          : widget.userid.toString();

      await Repository.postApiService(EndPoints.verifyOtp, {
        "user_id": userIdToSend,
        "otp": otp,
        "token": Preferences.getFcmToken() ?? "testing",
      }).then((value) async {
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            // 🔹 1. Merge verified response into userData & Preferences
            final currentUserId = (parsed["user_id"] ?? userIdToSend).toString();
            Map<String, dynamic> mergedUser = {};
            if (userData is Map) {
              mergedUser.addAll(Map<String, dynamic>.from(userData));
            }
            if (parsed is Map) {
              parsed.forEach((k, v) {
                if (v != null) mergedUser[k.toString()] = v;
              });
            }
            mergedUser["user_id"] = currentUserId;
            userData = mergedUser;
            Preferences.setUserDetails(json.encode(mergedUser));

            // 🔹 2. Customer vs Provider role validation
            final isCustomer = (mergedUser["customer"] == "1" ||
                mergedUser["customer"] == 1 ||
                mergedUser["role"] == "customer" ||
                mergedUser["user_type"] == "customer");
            final isProvider = (mergedUser["provider"] == "1" ||
                mergedUser["provider"] == 1 ||
                mergedUser["role"] == "provider" ||
                mergedUser["user_type"] == "provider");
            final isCustomerOnly = isCustomer && !isProvider;

            if (isCustomerOnly) {
              _isLoading = false;
              UtilClass.hideProgress();
              if (mounted) {
                UtilClass.showAlertDialog(
                  context: context,
                  message:
                      "This phone number is registered as a Customer. Please sign up as a GoBuddy Provider.",
                );
              }
              return;
            }

            // 🔹 3. Progressive Onboarding: determine where user stopped
            String targetRoute = Config.dashboardcRouteName;

            // Step A: Check if KYC documents are uploaded
            bool hasDocs = false;
            try {
              final ekycResp = await Repository.postApiService(
                EndPoints.getEkycDetails,
                {"user_id": currentUserId},
              );
              final dynamic parsedEkyc =
                  ekycResp is String ? json.decode(ekycResp) : ekycResp;
              if (parsedEkyc != null &&
                  (parsedEkyc["status"] == "success" ||
                      parsedEkyc["status"] == "valid" ||
                      parsedEkyc["status"] == true)) {
                final front = parsedEkyc["aadhar_front"] ??
                    parsedEkyc["data"]?["aadhar_front"];
                if (front != null && front.toString().trim().isNotEmpty) {
                  hasDocs = true;
                }
              }
            } catch (e) {
              print("eKYC check error: $e");
            }

            // Fallback check on user data ekyc field if API was unavailable
            if (!hasDocs) {
              final ekycVal = (mergedUser["ekyc"] ?? "").toString().trim();
              if (ekycVal.isNotEmpty && ekycVal != "0") {
                hasDocs = true;
              }
            }

            if (!hasDocs) {
              // ➡️ User stopped before uploading documents -> Go to Document Verification
              targetRoute = Config.ekycRouteName;
            } else {
              // Documents exist. Now Step B: Check if Registration Fee is paid
              bool isFeePaid = false;
              if (mergedUser["registration_fee"] == "1" ||
                  mergedUser["registration_fee"] == 1 ||
                  mergedUser["registration_fee_status"] == "1" ||
                  mergedUser["registration_fee_status"] == 1 ||
                  mergedUser["status"] == "1" ||
                  mergedUser["status"] == 1) {
                isFeePaid = true;
              }

              if (!isFeePaid) {
                try {
                  final profResp = await Repository.postApiService(
                    EndPoints.getProfileDetails,
                    {"user_id": currentUserId},
                  );
                  final dynamic parsedProf =
                      profResp is String ? json.decode(profResp) : profResp;
                  if (parsedProf != null && parsedProf["status"] == "valid") {
                    final p = parsedProf["profile"] ?? parsedProf["data"];
                    if (p is Map) {
                      p.forEach((k, v) {
                        if (v != null) mergedUser[k.toString()] = v;
                      });

                      final adminApproval = (p["admin_approval_provider"] ?? "")
                          .toString()
                          .toLowerCase()
                          .trim();
                      final ekycStat = (p["ekyc_status"] ?? "")
                          .toString()
                          .toLowerCase()
                          .trim();
                      final ekycName = (p["ekyc_status_name"] ?? "")
                          .toString()
                          .toLowerCase()
                          .trim();
                      final subCount = int.tryParse(
                              parsedProf["subscription_count"]?.toString() ??
                                  "0") ??
                          0;
                      final userDbStatus = (p["status"] ?? "").toString().trim();

                      if (adminApproval == "approved" ||
                          adminApproval == "1" ||
                          ekycStat == "1" ||
                          ekycStat == "approved" ||
                          ekycName == "approved" ||
                          subCount > 0 ||
                          p["registration_fee"] == "1" ||
                          p["registration_fee_status"] == "1" ||
                          userDbStatus == "1") {
                        isFeePaid = true;
                        mergedUser["registration_fee"] = "1";
                        mergedUser["registration_fee_status"] = "1";
                      }
                      Preferences.setUserDetails(json.encode(mergedUser));
                    }
                  }
                } catch (e) {
                  print("Profile check error: $e");
                }
              }

              if (!isFeePaid) {
                // ➡️ User uploaded documents, but dropped off before paying registration fee -> Go to Registration Fee
                targetRoute = Config.regiFeeRouteName;
              } else {
                // ➡️ Fully completed onboarding -> Go to Dashboard
                targetRoute = Config.dashboardcRouteName;
              }
            }

            _isLoading = false;
            UtilClass.hideProgress();
            if (mounted) {
              _showSuccessDialog(targetRoute);
            }
          } else {
            _isLoading = false;
            UtilClass.hideProgress();
            if (mounted) {
              UtilClass.showAlertDialog(
                context: context,
                message: parsed["message"] ?? "Invalid OTP",
              );
            }
          }
        } catch (e) {
          _isLoading = false;
          UtilClass.hideProgress();
          print("OTP verification error: $e");
          if (mounted) {
            UtilClass.showAlertDialog(
              context: context,
              message: "Failed to verify OTP. Please try again.",
            );
          }
        }
      });
    } else {
      _isLoading = false;
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void _showSuccessDialog(String targetRoute) {
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
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      targetRoute,
                      (route) => false,
                    );
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
                            AutofillGroup(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(4, (index) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: MyColors.lightGreen2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: controllers[index]
                                                .text
                                                .isNotEmpty
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
                                      autofillHints: const [
                                        AutofillHints.oneTimeCode,
                                      ],
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
