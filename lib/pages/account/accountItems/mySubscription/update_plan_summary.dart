import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobuddy/components/coupon_applied_alert.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../components/custom_back_button.dart';
import '../../../paymentGateway/payment_screen.dart';

class UpdateSummaryScreen extends StatefulWidget {
  final String title;
  final String oldPlan;
  final int oldPrice;
  final String newPlan;
  final int newPrice;
  final String couponCode;
  final int discount;
  final dynamic subscription;

  const UpdateSummaryScreen({
    super.key,
    this.title = "Summary",
    this.oldPlan = "AC Technician\nBasic Plan (20 Jobs)",
    this.oldPrice = 999,
    this.newPlan = "AC Technician\nBasic Plan (40 Jobs)",
    this.newPrice = 1499,
    this.couponCode = "AKSH1007",
    this.discount = 150,
    required this.subscription,
  });

  @override
  State<UpdateSummaryScreen> createState() => _UpdateSummaryScreenState();
}

class _UpdateSummaryScreenState extends State<UpdateSummaryScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool isCouponApplied = true;
  bool _isCouponApplied = false;
  String _appliedCoupon = '';
  String _appliedCouponAmount = '0';
  dynamic userData = {};
  late Razorpay razorpay;

  @override
  void initState() {
    super.initState();
    razorpay = Razorpay();
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    print(widget.subscription);
  }

  void _applyCoupon() {
    if (_couponController.text.isNotEmpty) {
      coupounAPIData();
    }
  }

  bool get _isRenewal {
    final rawStatus =
        (widget.subscription["status_text"] ?? "").toString().toLowerCase().trim();
    final rem = int.tryParse((widget.subscription["remaining"] ?? "").toString());
    final statusVal = widget.subscription["status"]?.toString();
    return rawStatus == "completed" ||
        rawStatus == "expired" ||
        statusVal == "0" ||
        (rem != null && rem <= 0);
  }

  String get totalPrice {
    final selectedPkg = widget.subscription["selectedPackage"];
    final amt = selectedPkg?["amount"] ?? selectedPkg?["package_amount"] ?? "0";
    double total = double.tryParse(amt.toString()) ?? 0.0;
    return total.toString();
  }

  String get exttotalPrice {
    if (_isRenewal) return "0.0";
    final curAmt = widget.subscription["package_amount"] ??
        widget.subscription["package_details"]?["amount"] ??
        widget.subscription["amount"] ??
        widget.subscription["package"] ??
        "0";
    double total = double.tryParse(curAmt.toString()) ?? 0.0;
    return total.toString();
  }

  double get gstAmount {
    double selected = double.tryParse(totalPrice) ?? 0.0;
    double current = double.tryParse(exttotalPrice) ?? 0.0;
    double diff = _isRenewal ? selected : (selected - current);
    if (diff <= 0) diff = selected;
    if (diff <= 0) return 0.0;
    return diff * 0.18;
  }

  String get finalPrice {
    double selected = double.tryParse(totalPrice) ?? 0.0;
    double current = double.tryParse(exttotalPrice) ?? 0.0;
    double coupon = double.tryParse(_appliedCouponAmount) ?? 0.0;

    double diff = _isRenewal ? selected : (selected - current);
    if (diff <= 0) {
      diff = selected;
    }
    if (diff <= 0) {
      return "0";
    }

    double total = diff + (diff * 0.18) - coupon;
    return (total < 0 ? 0.0 : total).toStringAsFixed(2);
  }

  void coupounAPIData() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.coupounApi, {
        "user_id": userData["user_id"] ?? "",
        "coupon": _couponController.text,
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = await json.decode(value);
        try {
          if (parsed["status"] == "valid") {
            var amount = parsed["coupon_amount"];
            setState(() {
              _isCouponApplied = true;
              _appliedCouponAmount = amount;
              _appliedCoupon = _couponController.text;
            });

            showDialog(
              context: context,
              builder: (_) => ReferralDialog(
                title: "Offer code applied",
                subtitle: "₹ $amount savings with this code",
                image: "assets/images/couponCode.png",
              ),
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
  void dispose() {
    razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  void callRagerPayment() async {
    var numPrice = double.tryParse(finalPrice) ?? 0.0;
    if (numPrice <= 0) {
      callpaymentVeifyAPI("PLAN_DOWNGRADE_ADJUSTMENT");
      return;
    }

    final int amountInPaise = (numPrice * 100).round();
    String contact = userData["phone_number"] ?? userData["phone"] ?? '';
    String email = userData["email"] ?? '';

    var options = {
      'key': Config.razorpayKey,
      'amount': amountInPaise,
      'name': 'Go buddy',
      'description': 'Upgrade Package',
      'currency': 'INR',
      'retry': {'enabled': true, 'max_count': 1},
      'prefill': {
        'contact': contact.isNotEmpty ? contact : '9999999999',
        'email': email.isNotEmpty ? email : 'test@gobuddy.com',
      },
    };

    try {
      razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      showAlertDialog(context, "Payment Error", "Unable to open payment screen: $e");
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint("Razorpay error: code ${response.code}, msg: ${response.message}");
    showAlertDialog(
      context,
      "Payment Failed",
      "${response.message ?? 'Payment failed. Please try again.'}",
    );
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    callpaymentVeifyAPI(response.paymentId!);
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
    var internet = await UtilClass.checkInternet();
    debugPrint("Upgrading subscription details: ${widget.subscription}");

    if (!internet) {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
      return;
    }

    // ignore: use_build_context_synchronously
    UtilClass.showProgress(context: context);

    try {
      // 1. Record payment transaction in provider_subscription_payment
      try {
        await Repository.postApiService(EndPoints.subPayment, {
          "user_id": userData["user_id"] ?? "",
          "coupon": _couponController.text,
          "amount": finalPrice,
          "saving_amount": _appliedCouponAmount,
          "payment_id": paymentid,
          "subscription_ids": widget.subscription["subscription_id"]?.toString() ?? "",
        });
      } catch (e) {
        debugPrint("Error recording payment in subPayment: $e");
      }

      // 2. Call upgrade_provider_subscription via raw JSON
      final selectedPkg = widget.subscription["selectedPackage"] ?? {};
      final packageVal =
          selectedPkg["jobs"] ?? selectedPkg["package_value"] ?? selectedPkg["value"] ?? 0;
      final packageAmt = selectedPkg["amount"] ?? selectedPkg["package_amount"] ?? 0;

      final input = {
        "payment_id": paymentid,
        "subscription_id": widget.subscription["subscription_id"],
        "subscription":
            widget.subscription["plan"]?['plan'] ?? widget.subscription["subscription"] ?? "",
        "jobs": packageVal,
        "package": packageVal,
        "package_amount": packageAmt,
        "amount": finalPrice,
        "services": widget.subscription["services"] ?? [],
        "addons": widget.subscription["addons"] ?? [],
      };

      final value = await Repository.postApiRawService(EndPoints.upgradeSub, input);
      UtilClass.hideProgress();

      dynamic parsed = value;
      if (value is String) {
        try {
          parsed = json.decode(value);
        } catch (_) {}
      }

      if (parsed != null &&
          (parsed["status"] == "valid" ||
              parsed["status"] == true ||
              parsed["status"] == 1)) {
        if (!mounted) return;
        final screenNav = Navigator.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop(); // close the dialog first
              }
              if (screenNav.canPop()) {
                screenNav.pop(true); // return to MySubscriptionsScreen & trigger refresh
              } else {
                screenNav.pushReplacementNamed(
                  Config.mySubscriptionsRouteName,
                  arguments: {'issubscription': true},
                );
              }
            });

            return const ReferralDialog(
              title: "Payment Successful",
              subtitle: "Thank You for renewing/upgrading the subscription.",
              image: "assets/images/greentick.png",
            );
          },
        );
      } else {
        if (!mounted) return;
        UtilClass.showAlertDialog(
          context: context,
          message: parsed is Map
              ? (parsed["message"] ?? "Failed to upgrade subscription")
              : "Failed to upgrade subscription",
        );
      }
    } catch (e) {
      UtilClass.hideProgress();
      debugPrint("Upgrade API error: $e");
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Something went wrong while processing the upgrade.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double width = size.width;
    final double height = size.height;

    final String oldJobsStr = (widget.subscription["jobs"] ??
            widget.subscription["package_value"] ??
            widget.subscription["package_details"]?["value"] ??
            "0")
        .toString();
    final int oldPriceInt = (double.tryParse((widget.subscription["package_amount"] ??
                    widget.subscription["package"] ??
                    widget.subscription["amount"] ??
                    widget.subscription["package_details"]?["amount"] ??
                    "0")
                .toString()) ??
            0.0)
        .toInt();

    final String newPlanName = (widget.subscription["plan"]?["plan"] ??
            widget.subscription["subscription"] ??
            "")
        .toString();
    final String newJobsStr = (widget.subscription["selectedPackage"]?["jobs"] ??
            widget.subscription["selectedPackage"]?["package_value"] ??
            oldJobsStr)
        .toString();
    final int newPriceInt = (double.tryParse((widget.subscription["selectedPackage"]?["amount"] ??
                    widget.subscription["selectedPackage"]?["package_amount"] ??
                    "0")
                .toString()) ??
            0.0)
        .toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// ---------- HEADER ----------
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.015,
              ),
              child: Row(
                children: [
                  CustomBackButton(),
                  SizedBox(width: width * 0.03),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ---------- UPDATE PLAN ----------
                      Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: Colors.orange,
                            size: width * 0.06,
                          ),
                          SizedBox(width: width * 0.02),
                          Text(
                            _isRenewal ? "Renew Plan" : "Update Plan",
                            style: TextStyle(
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.015),

                      /// ---------- PLAN CARD ----------
                      Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPlanText(
                                    "${widget.subscription["category"] ?? ""}\n${widget.subscription["subscription"] ?? ""} ($oldJobsStr Jobs)",
                                    oldPriceInt,
                                    width,
                                    isOld: true,
                                  ),
                                  SizedBox(height: height * 0.01),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  SizedBox(height: height * 0.01),
                                  _buildPlanText(
                                    "${widget.subscription["category"] ?? ""}\n$newPlanName ($newJobsStr Jobs)",
                                    newPriceInt,
                                    width,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.02),

                      /// ---------- OFFERS ----------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.local_offer, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  "Offers",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Text('Enter Coupen Code  (optional)'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: !_isCouponApplied
                                      ? TextField(
                                          controller: _couponController,
                                          decoration: InputDecoration(
                                            hintText: _isCouponApplied
                                                ? _appliedCoupon
                                                : "Enter coupon code",
                                            filled: true,
                                            fillColor: Colors.grey.shade200,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                          ),
                                          enabled: !_isCouponApplied,
                                        )
                                      : ActionChip(
                                          label: Text(_couponController.text),
                                          avatar: const Icon(Icons.delete),
                                          onPressed: () {
                                            _couponController.text = "";
                                            _appliedCouponAmount = "0";
                                            setState(() {
                                              _isCouponApplied = false;
                                              _appliedCouponAmount = "0";
                                            });
                                          },
                                        ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _isCouponApplied ? null : _applyCoupon,
                                  child: Container(
                                    height: 45,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isCouponApplied
                                          ? Colors.green
                                          : null,
                                      border: Border.all(
                                        color: Colors.green,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: _isCouponApplied
                                          ? const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Applied",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              "Apply",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.02),

                      /// ---------- PRICE SUMMARY ----------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "₹$totalPrice",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (!_isRenewal)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Existing plan",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "₹$exttotalPrice",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Discount",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "- ₹$_appliedCouponAmount",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (gstAmount > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "GST (18%)",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    "+ ₹${gstAmount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "To Pay",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "₹$finalPrice",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: height * 0.02),

                      // Bottom Pay Button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "₹ $finalPrice",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "To be paid now",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              callRagerPayment();
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Center(
                                child: Text(
                                  "Proceed to Pay",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: height * 0.12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------- Helper Widgets ----------
  Widget _buildPlanText(
    dynamic title,
    int price,
    double width, {
    bool isOld = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.w600,
            color: isOld ? Colors.black87 : Colors.black,
          ),
        ),
        Text(
          "₹ $price",
          style: TextStyle(
            fontSize: width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
