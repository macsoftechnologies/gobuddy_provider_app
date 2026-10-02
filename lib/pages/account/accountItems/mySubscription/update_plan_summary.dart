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

// import '../../utilites/custombackbutton.dart';
// import '../payment_screen.dart';

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
    // final data = json.decode(subscriptionJson);
    // subscriptions = data["subscriptions"];

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

  String get totalPrice {
    double total = double.parse(
      widget.subscription["selectedPackage"]["amount"],
    );

    return total.toString();
  }

  String get exttotalPrice {
    double total = double.parse(widget.subscription["package"]);

    return total.toString();
  }

  double get gstAmount {
    double selected = double.tryParse(widget.subscription["selectedPackage"]?["amount"]?.toString() ?? "0") ?? 0.0;
    double current = double.tryParse(widget.subscription["package"]?.toString() ?? "0") ?? 0.0;
    double diff = selected - current;
    if (diff <= 0) return 0.0;
    return diff * 0.18;
  }

  String get finalPrice {
    double selected = double.tryParse(
      widget.subscription["selectedPackage"]?["amount"]?.toString() ?? "0",
    ) ?? 0.0;

    double current = double.tryParse(
      widget.subscription["package"]?.toString() ?? "0",
    ) ?? 0.0;

    double coupon = double.tryParse(_appliedCouponAmount) ?? 0.0;

    double diff = selected - current;
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

  /////////
  ///////
  ///
  ///
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
      if (Config.razorpayKey.startsWith("rzp_test_")) {
        _showTestPaymentFallback(
          reason: "Unable to open Razorpay gateway: $e",
          onSimulateSuccess: () {
            callpaymentVeifyAPI("TEST_UPGRADE_${DateTime.now().millisecondsSinceEpoch}");
          },
        );
      } else {
        showAlertDialog(context, "Payment Error", "Unable to open payment screen: $e");
      }
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint("Razorpay error: code ${response.code}, msg: ${response.message}");
    if (Config.razorpayKey.startsWith("rzp_test_")) {
      _showTestPaymentFallback(
        reason: "${response.message ?? 'Payment was cancelled or failed'}",
        onSimulateSuccess: () {
          callpaymentVeifyAPI("TEST_UPGRADE_${DateTime.now().millisecondsSinceEpoch}");
        },
      );
    } else {
      showAlertDialog(
        context,
        "Payment Failed",
        "${response.message ?? 'Payment failed. Please try again.'}",
      );
    }
  }

  void _showTestPaymentFallback({
    required String reason,
    required VoidCallback onSimulateSuccess,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.payment, color: Colors.orange),
            SizedBox(width: 8),
            Text("Payment (Test Mode)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "$reason\n\nYou are in Test Mode (using test key). Would you like to simulate successful payment to complete upgrade testing?",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onSimulateSuccess();
            },
            child: const Text("Simulate Success"),
          ),
        ],
      ),
    );
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    /*
    * Payment Success Response contains three values:
    * 1. Order ID
    * 2. Payment ID
    * 3. Signature
    * */
    // showAlertDialog(
    //   context,
    //   "Payment Successful",
    //   "Payment ID: ${response.paymentId}",
    // );

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
    // set up the buttons
    Widget continueButton = ElevatedButton(
      child: const Text("Continue"),
      onPressed: () {},
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(title: Text(title), content: Text(message));
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void callpaymentVeifyAPI(String paymentid) async {
    var internet = await UtilClass.checkInternet();
    print(widget.subscription);

    if (internet) {

      var input  = {
      
        'payment_id':paymentid,
        "subscription_id": widget.subscription["subscription_id"],
        "subscription": widget.subscription["plan"]['plan'],
        "jobs": widget.subscription["selectedPackage"]['jobs'],
        "package": widget.subscription["selectedPackage"]['amount'],
        "amount": finalPrice,
      };
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.upgradeSub, input).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            showDialog(
              context: context,
              builder: (context) {
                Future.delayed(const Duration(seconds: 3), () {
                  Navigator.of(context).pop(); // close the dialog first
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Config.getActiveSubscriptionsRouteName,
                    (route) => false,
                  );
                });

                return const ReferralDialog(
                  title: "Payment Successful",
                  subtitle: "Thank You for upgrading the subscription.",
                  image: "assets/images/greentick.png",
                );
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

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double width = size.width;
    final double height = size.height;

    int total = widget.newPrice;
    int discount = isCouponApplied ? widget.discount : 0;
    int toPay = total - discount;

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
                            "Update Plan",
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
                                    widget.subscription["category"] +
                                        "\n" +
                                        widget.subscription["subscription"] +
                                        " (" +
                                        widget.subscription["jobs"] +
                                        ")",
                                    double.parse(
                                      widget.subscription["package"],
                                    ).toInt(),
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
                                    widget.subscription["category"] +
                                        "\n" +
                                        widget.subscription["plan"]["plan"] +
                                        " (" +
                                        widget
                                            .subscription["selectedPackage"]["jobs"] +
                                        ")",

                                    double.parse(
                                      widget
                                          .subscription["selectedPackage"]["amount"],
                                    ).toInt(),
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
                      // Coupon Section
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
                                          avatar: Icon(Icons.delete),
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
                                        color: _isCouponApplied
                                            ? Colors.green
                                            : Colors.green,
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
                      // _buildPriceSection(total, discount, toPay, width, height),
                      // To Pay Section
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
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(builder: (context) => PaymentMethodScreen(amount: 0.00, fromScreen: 'subscription',)),
                              // );
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

            /// ---------- BOTTOM BAR ----------
            // Container(
            //   padding: EdgeInsets.symmetric(
            //     horizontal: width * 0.05,
            //     vertical: height * 0.015,
            //   ),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.08),
            //         blurRadius: 6,
            //         offset: const Offset(0, -2),
            //       ),
            //     ],
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             "₹ $toPay",
            //             style: TextStyle(
            //               fontSize: width * 0.055,
            //               fontWeight: FontWeight.bold,
            //               color: Colors.black87,
            //             ),
            //           ),
            //           Text(
            //             "To be paid now",
            //             style: TextStyle(
            //               fontSize: width * 0.035,
            //               color: Colors.grey,
            //             ),
            //           ),
            //         ],
            //       ),
            //       ElevatedButton(
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.green,
            //           padding: EdgeInsets.symmetric(
            //             horizontal: width * 0.1,
            //             vertical: height * 0.018,
            //           ),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //         ),
            //         onPressed: () {
            //           // Handle payment
            //           Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //               builder: (context) => PaymentMethodScreen(
            //                 amount: toPay.toDouble(),
            //                 fromScreen: '',
            //               ),
            //             ),
            //           );
            //         },
            //         child: Text(
            //           "Proceed to Pay",
            //           style: TextStyle(
            //             fontSize: width * 0.045,
            //             fontWeight: FontWeight.w600,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
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

  Widget _buildOfferSection(double width, double height) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.green, size: width * 0.06),
              SizedBox(width: width * 0.02),
              Text(
                "Offers",
                style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          Text(
            "Enter coupon code and save on this Packages",
            style: TextStyle(fontSize: width * 0.04, color: Colors.black87),
          ),
          SizedBox(height: height * 0.01),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.015,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade200,
                  ),
                  child: Text(
                    widget.couponCode,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
              if (isCouponApplied)
                Text(
                  "✔ Applied",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
    int total,
    int discount,
    int toPay,
    double width,
    double height,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.green, size: width * 0.06),
              SizedBox(width: width * 0.02),
              Text(
                "To pay  ₹ $total",
                style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.015),
          Divider(thickness: 1, color: Colors.grey.shade300),
          _buildPriceRow("Total", "₹ $total", width),
          _buildPriceRow(
            "Discount on coupon",
            "- ₹ $discount",
            width,
            isDiscount: true,
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          _buildPriceRow("To Pay", "₹ $toPay", width, isBold: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    double width, {
    bool isDiscount = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: width * 0.045,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isDiscount ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
