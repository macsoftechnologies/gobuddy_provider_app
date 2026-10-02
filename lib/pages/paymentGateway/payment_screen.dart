import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobuddy/components/custom_back_button.dart';
import 'package:gobuddy/components/coupon_applied_alert.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../utils/config.dart';

import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';

class PaymentMethodScreen extends StatefulWidget {
  
  final double amount;
  final String fromScreen;
  final VoidCallback? onBackPressed;
  final Function(PaymentMethod)? onPaymentMethodSelected;
  final VoidCallback? onPayPressed;

  const PaymentMethodScreen({
    super.key,
    required this.amount,
    required this.fromScreen,
    this.onBackPressed,
    this.onPaymentMethodSelected,
    this.onPayPressed,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PaymentMethod? selectedPaymentMethod = PaymentMethod.phonePe;
    dynamic userData= {};
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
  void callpaymentVeifyAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.onetimeregistrationApi, {
        "user_id": userData["user_id"] ?? "",
        "amount": widget.amount.toStringAsFixed(0),
        "referral_code": "",
        "saving_amount": "0",
        "payment_id": "PAY_${DateTime.now().millisecondsSinceEpoch}",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = value is String ? json.decode(value) : value;
          if (parsed is Map && (parsed["status"] == "valid" || parsed["status"] == true || parsed["status"] == "success")) {
            showDialog(
              context: context,
              builder: (context) {
                Future.delayed(const Duration(seconds: 3), () {
                  Navigator.of(context).pop(); // close the dialog first
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(Config.regiSuccessRouteName);
                });

                return const ReferralDialog(
                  title: "Payment Successful",
                  subtitle: "Thank You for your payment.",
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
                  : "Payment verification failed",
            );
          }
        } catch (e) {
          print(e);
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(context, screenWidth),

            // UPI Section
            _buildUPISection(screenWidth),

            // Payment Methods Section
            Expanded(
              child: _buildPaymentMethodsSection(screenWidth, screenHeight),
            ),

            // Bottom Payment Section
            _buildBottomPaymentSection(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 16,
      ),
      child: Row(
        children: [
          CustomBackButton(),
          SizedBox(width: screenWidth * 0.04),
          const Text(
            'Choose how to pay',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUPISection(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/UPi.png', // You'll need to add UPI logo
            width: 40,
            height: 24,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'UPI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          const Text(
            'UNIFIED PAYMENTS INTERFACE',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection(double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
        top: 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPaymentMethodTile(
            PaymentMethod.phonePe,
            'PhonePe',
            'assets/images/PhonePe.png',
            const Color(0xFF5F259F),
          ),
          const Divider(height: 22, color: Color(0xFFE0E0E0)),
          _buildPaymentMethodTile(
            PaymentMethod.googlePay,
            'Google Pay',
            'assets/images/GooglePay.png',
            Colors.blue,
          ),
          const Divider(height: 22, color: Color(0xFFE0E0E0)),
          _buildPaymentMethodTile(
            PaymentMethod.paytm,
            'Paytm',
            'assets/images/Paytm.png',
            const Color(0xFF00BAF2),
          ),
          const Divider(height: 22, color: Color(0xFFE0E0E0)),
          _buildUPIIdSection(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    String iconPath,
    Color iconColor,
  ) {
    final isSelected = selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
        widget.onPaymentMethodSelected?.call(method);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              // decoration: BoxDecoration(
              //   color: iconColor.withOpacity(0.1),
              //   borderRadius: BorderRadius.circular(22),
              // ),
              child: Image.asset(iconPath, height: 12, width: 14),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFBDBDBD),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(PaymentMethod method, Color color) {
    switch (method) {
      case PaymentMethod.phonePe:
        return Icon(Icons.phone_android, color: color, size: 24);
      case PaymentMethod.googlePay:
        return Icon(Icons.payment, color: color, size: 24);
      case PaymentMethod.paytm:
        return Icon(Icons.account_balance_wallet, color: color, size: 24);
      case PaymentMethod.upiId:
        return Icon(Icons.add, color: color, size: 24);
    }
  }

  Widget _buildUPIIdSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = PaymentMethod.upiId;
        });
        widget.onPaymentMethodSelected?.call(PaymentMethod.upiId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add, color: Color(0xFF666666), size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Enter UPI ID',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPaymentSection(double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const Text(
                    'To be paid now',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  callpaymentVeifyAPI();
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pay',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PaymentMethod { phonePe, googlePay, paytm, upiId }
