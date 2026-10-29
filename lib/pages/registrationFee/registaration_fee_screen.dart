import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../components/coupon_applied_alert.dart';
import '../../utils/config.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RegistrationFeeScreen extends StatefulWidget {
  const RegistrationFeeScreen({super.key});

  @override
  State<RegistrationFeeScreen> createState() => _RegistrationFeeScreenState();
}

class _RegistrationFeeScreenState extends State<RegistrationFeeScreen> {
  final TextEditingController _referralController = TextEditingController();
  dynamic userData = {};
  double regFee = 300.0;
  double referralSaving = 100.0;
  bool isReferralApplied = false;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);
    _loadUserData();
    _fetchRegistrationFee();
  }

  void _loadUserData() {
    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      try {
        userData = json.decode(userDataValue);
        final savedRef = (userData["referral_code"] ?? "").toString().trim();
        if (savedRef.isNotEmpty && _referralController.text.isEmpty) {
          _referralController.text = savedRef;
        }
      } catch (e) {
        print("Error decoding userData: $e");
      }
    }
  }

  Future<void> _fetchRegistrationFee() async {
    try {
      final response = await Repository.postApiService(
        EndPoints.getOneTimeRegistrationFee,
        {},
      );
      dynamic parsed = response is String ? json.decode(response) : response;
      if (parsed != null && parsed["status"] == "valid" && parsed["registrationfee"] != null) {
        setState(() {
          regFee = double.tryParse(parsed["registrationfee"]["fee"]?.toString() ?? "300") ?? 300.0;
          referralSaving = double.tryParse(parsed["registrationfee"]["referral_saving"]?.toString() ?? "100") ?? 100.0;
        });
      }
    } catch (e) {
      print("Error fetching registration fee: $e");
    }
  }

  Future<void> _applyReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Please enter a referral code",
      );
      return;
    }

    final hasInternet = await UtilClass.checkInternet();
    if (!hasInternet) {
      if (mounted) {
        UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
      }
      return;
    }

    if (mounted) {
      UtilClass.showProgress(context: context);
    }

    try {
      final response = await Repository.postApiService(
        EndPoints.getReferralDetails,
        {"referral_id": code},
      );
      UtilClass.hideProgress();

      dynamic parsed = response is String ? json.decode(response) : response;
      if (parsed != null &&
          (parsed["status"] == "valid" ||
              parsed["status"] == true ||
              parsed["status"] == "success")) {
        // Prevent self-referral
        if (parsed["referraldetails"] != null && parsed["referraldetails"] is Map) {
          final refMap = parsed["referraldetails"] as Map;
          final refUserId = refMap["id"]?.toString() ?? "";
          final currentUserId = (userData["user_id"] ?? userData["id"] ?? "").toString();
          final currentRefId = (userData["referral_id"] ?? "").toString();

          if ((refUserId.isNotEmpty && refUserId == currentUserId) ||
              (currentRefId.isNotEmpty && currentRefId.toUpperCase() == code.toUpperCase())) {
            if (mounted) {
              UtilClass.showAlertDialog(
                context: context,
                message: "You cannot use your own referral code.",
              );
            }
            return;
          }

          final dynSaving = double.tryParse(refMap["saving_amount"]?.toString() ??
              refMap["amount"]?.toString() ?? "");
          if (dynSaving != null && dynSaving > 0) {
            referralSaving = dynSaving;
          }
        }

        if (mounted) {
          setState(() {
            isReferralApplied = true;
          });

          showDialog(
            context: context,
            builder: (dialogContext) {
              Future.delayed(const Duration(seconds: 2), () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });
              return ReferralDialog(
                title: "Offer code applied",
                subtitle: "₹ ${referralSaving.toStringAsFixed(0)} savings with this code",
                image: "assets/images/couponCode.png",
              );
            },
          );
        }
      } else {
        if (mounted) {
          final msg = (parsed != null && parsed["message"] != null)
              ? parsed["message"].toString()
              : "Invalid referral code. Please enter a valid code.";
          UtilClass.showAlertDialog(context: context, message: msg);
        }
      }
    } catch (e) {
      UtilClass.hideProgress();
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Failed to validate referral code. Please try again.",
        );
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _referralController.dispose();
    super.dispose();
  }

  void callRagerPayment() async {
    double payableAmount = isReferralApplied && (regFee - referralSaving > 0)
        ? (regFee - referralSaving)
        : regFee;

    if (payableAmount <= 0) {
      callpaymentVeifyAPI("FREE_REGISTRATION_${DateTime.now().millisecondsSinceEpoch}");
      return;
    }

    int amountInPaise = (payableAmount * 100).round();

    String contact = userData["phone_number"] ?? userData["phone"] ?? "";
    String email = userData["email"] ?? "";

    var options = {
      'key': Config.razorpayKey,
      'amount': amountInPaise,
      'name': 'Go buddy',
      'description': 'One time registration Fee',
      'currency': 'INR',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact.isNotEmpty ? contact : '9999999999',
        'email': email.isNotEmpty ? email : 'test@gobuddy.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      showAlertDialog(context, "Payment Error", "Unable to open payment screen: $e");
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint("Razorpay failure: code ${response.code}, msg: ${response.message}");
    showAlertDialog(
      context,
      "Payment Failed",
      "${response.message ?? 'Payment failed. Please try again.'}",
    );
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    callpaymentVeifyAPI(response.paymentId ?? "PAY_SUCCESS_${DateTime.now().millisecondsSinceEpoch}");
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    showAlertDialog(
      context,
      "External Wallet Selected",
      "${response.walletName}",
    );
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    AlertDialog alert = AlertDialog(title: Text(title), content: Text(message));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void callpaymentVeifyAPI(String paymentid) async {
    final userId = userData["user_id"]?.toString() ?? "";
    if (userId.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "User session expired or invalid. Please re-login.",
      );
      return;
    }
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      double payableAmount = isReferralApplied && (regFee - referralSaving > 0)
          ? (regFee - referralSaving)
          : regFee;
      await Repository.postApiService(EndPoints.onetimeregistrationApi, {
        "user_id": userId,
        "amount": payableAmount.toStringAsFixed(0),
        "referral_code": _referralController.text.trim(),
        "saving_amount": isReferralApplied ? referralSaving.toStringAsFixed(0) : "0",
        "payment_id": paymentid,
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = value is String ? json.decode(value) : value;
          if (parsed is Map && (parsed["status"] == "valid" || parsed["status"] == true || parsed["status"] == "success")) {
            try {
              final userMap = Map<String, dynamic>.from(userData);
              userMap['registration_fee'] = '1';
              userMap['registration_fee_status'] = '1';
              userMap['status'] = '1';
              Preferences.setUserDetails(json.encode(userMap));
            } catch (_) {}

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogCtx) {
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Config.regiSuccessRouteName,
                    (route) => false,
                  );
                });

                return const ReferralDialog(
                  title: "Payment Successful",
                  subtitle: "Thank you for completing your registration fee payment.",
                  image: "assets/images/greentick.png",
                );
              },
            );
          } else {
            // ignore: use_build_context_synchronously
            UtilClass.showAlertDialog(
              // ignore: use_build_context_synchronously
              context: context,
              message: (parsed is Map && parsed["message"] != null)
                  ? parsed["message"].toString()
                  : "Registration fee payment failed.",
            );
          }
        } catch (e) {
          print(e);
          UtilClass.showAlertDialog(
            context: context,
            message: "Error processing payment response: $e",
          );
        }
        if (parsed is Map && parsed["message"] != null) {
          print(parsed["message"]);
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  Future<void> _handleExit(BuildContext context) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Exit Payment"),
        content: const Text(
          "One-time registration fee payment is required to activate your provider account.\n\nYou can complete the payment at any time from your Account Setup Status.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Stay"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Back to Status", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        Config.onboardingStatusRouteName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleExit(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4CAF50),
        body: SafeArea(
          child: Container(
            width: deviceWidth,
            height: deviceHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF66BB6A), Color(0xFF4CAF50), Color(0xFF388E3C)],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
                child: Column(
                  children: [
                    // Close button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                          right: deviceWidth * 0.02,
                        ),
                        child: GestureDetector(
                          onTap: () => _handleExit(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: deviceHeight * 0.04),

                  // Main Icon container
                  Container(
                    width: deviceWidth * 0.35,
                    height: deviceWidth * 0.35,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Charts/graphs background
                        Container(
                          width: deviceWidth * 0.18,
                          height: deviceWidth * 0.15,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(painter: ChartPainter()),
                        ),
                        // Hand holding card
                        Positioned(
                          bottom: deviceWidth * 0.08,
                          right: deviceWidth * 0.05,
                          child: Container(
                            width: deviceWidth * 0.15,
                            height: deviceWidth * 0.08,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // Person figure
                        Positioned(
                          bottom: deviceWidth * 0.06,
                          left: deviceWidth * 0.12,
                          child: SizedBox(
                            width: 20,
                            height: 30,
                            child: CustomPaint(painter: PersonPainter()),
                          ),
                        ),
                        // Checkmark
                        Positioned(
                          top: deviceWidth * 0.05,
                          right: deviceWidth * 0.08,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFA726),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: deviceHeight * 0.03),

                  // Title
                  const Text(
                    'One Time Registration Fee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: deviceHeight * 0.01),

                  // Price
                  Text(
                    '₹ ${isReferralApplied && (regFee - referralSaving > 0) ? (regFee - referralSaving).toStringAsFixed(0) : regFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: deviceHeight * 0.02),

                  // Description in English
                  const Text(
                    'Your one-time registration fee will cover detailed App training to manage jobs and view your financial growth, and other materials supply.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: deviceHeight * 0.015),

                  // Contact number
                  const Text(
                    'For any inquiries Contact: 9177746889',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: deviceHeight * 0.025),

                  // Telugu text
                  const Text(
                    'మీ ఒక-సారి రిజిస్ట్రేషన్ ఫీజు ఉద్యోగాలను నిర్వహించడానికి మరియు మీ ఆర్థిక వృద్ధిని చూడటానికి వివరణాత్మక యాప్ శిక్షణను మరియు ఇతర సామగ్రి సరఫరాను కవర్ చేస్తుంది.\nఏవైనా విచారణలు కోసం సంప్రదించండి: 9177746889',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: deviceHeight * 0.04),

                  // Referral code section
                  const Text(
                    'Enter referral code ( Optional )',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: deviceHeight * 0.015),

                  // Input field and button
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: TextField(
                            controller: _referralController,
                            style: const TextStyle(color: Colors.white),
                            onSubmitted: (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(FocusNode()); // Hides keyboard
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter code',
                              hintStyle: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: deviceWidth * 0.04),
                      SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            if (isReferralApplied) {
                              setState(() {
                                isReferralApplied = false;
                                _referralController.clear();
                              });
                            } else {
                              _applyReferralCode();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: isReferralApplied ? Colors.red : const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(
                            isReferralApplied ? 'Remove' : 'Apply',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isReferralApplied ? Colors.red : const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: deviceHeight * 0.05),

                  // Continue button
                  GestureDetector(
                    onTap: () {
                      Future.delayed(const Duration(seconds: 1), () {
                        callRagerPayment();
                        //  Navigator.of(context).pop(); // Close the dialog
                        // Navigator.of(context).pushReplacementNamed(
                        //   Config.regiSuccessRouteName,);
                        //  Navigator.pushNamed(
                        //    context,
                        //    Config.paymentMethodRouteName,
                        //    arguments: {
                        //      "amount": 200.0,
                        //      "fromScreen": "reg_fee",
                        //    },
                        //  );
                      });
                    },
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF4CAF50),
                        size: 20,
                      ),
                    ),
                  ),


                  SizedBox(height: deviceHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

// Custom painter for the chart/graph illustration
class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2;

    final barWidth = size.width * 0.15;
    final spacing = size.width * 0.1;

    for (int i = 0; i < 3; i++) {
      final height = size.height * (0.3 + i * 0.2);
      final x = spacing + i * (barWidth + spacing);

      if (i == 0) {
        paint.color = Colors.red.shade400;
      } else if (i == 1) {
        paint.color = Colors.orange.shade400;
      } else {
        paint.color = Colors.blue.shade400;
      }

      final rect = Rect.fromLTWH(x, size.height - height, barWidth, height);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for the person figure
class PersonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange.shade600;

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.15,
      paint,
    );

    // Body
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.3,
        size.height * 0.4,
      ),
      paint,
    );

    // Arms
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.4,
        size.width * 0.8,
        size.width * 0.1,
      ),
      paint,
    );

    // Legs
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.75,
        size.width * 0.12,
        size.height * 0.25,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.53,
        size.height * 0.75,
        size.width * 0.12,
        size.height * 0.25,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
