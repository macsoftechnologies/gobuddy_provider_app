import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../../../components/coupon_applied_alert.dart';
import '../../../paymentGateway/payment_screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// import '../../utilites/coupon_applied_alert.dart';
// import '../payment_screen.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isCouponApplied = false;
  String _appliedCoupon = '';
  String _appliedCouponAmount = '0';
  // List of plans (Dynamic)
  List<dynamic> plans = [];

  List<dynamic> subDetails = [];
  // ignore: non_constant_identifier_names
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
          if (parsed["status"] == "valid" || parsed["status"] == true) {
            var amount = (parsed["coupon_amount"] ?? parsed["discount"] ?? parsed["saving_amount"] ?? "0").toString();
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

  void summaryDataAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.getprovSubscriptionApi, {
        "provider_id": userData["user_id"] ?? "",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = value;
          if (parsed["status"] == "valid") {
            plans = parsed["data"] ?? [];
            setState(() {
              plans = parsed["data"] ?? [];
            });

            if (plans.isNotEmpty) {
              var data = plans[0];
              print(data);
            }
          } else {
            setState(() {
              plans = [];
            });
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

  void deleteSubscAPI(String id) async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiServiceWithJson(EndPoints.deleteprovSubscriptionApi, {
        "subscription_id": id,
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            summaryDataAPI();
            //   plans = parsed["data"];
            // setState(() {
            //   plans = parsed["data"];
            // });

            // print(plans);
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

  List<dynamic> packages = [];
  dynamic summaryData = {};
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
    summaryDataAPI();
  }

  @override
  void dispose() {
    razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  String get totalPrice {
    double total = 0.0;
    for (var plan in plans) {
      var package = double.tryParse(plan["package"]?.toString() ?? "0") ?? 0.0;
      total += package;
      if (plan["addons"] is List) {
        for (var addon in plan["addons"]) {
          total += double.tryParse(addon["price"]?.toString() ?? "0") ?? 0.0;
        }
      }
    }
    return total.toString();
  }

  double get gstAmount => (double.tryParse(totalPrice) ?? 0.0) * 0.18;

  String get finalPrice {
    double total = double.tryParse(totalPrice) ?? 0.0;
    double coupon = double.tryParse(_appliedCouponAmount) ?? 0.0;
    double finalPrice = total + gstAmount - coupon;
    if (finalPrice < 0) finalPrice = 0.0;
    return finalPrice.toStringAsFixed(2);
  }

  String get DiscountPrice {
    double total = 0.0;
    for (var plan in plans) {
      var package = double.parse(plan["package"]);
      total += package;
    }
    return total.toString();
  }

  void removePlan(int index) {
    var subId = plans[index]["subscription_id"];
    deleteSubscAPI(subId);
    // setState(() {
    //   plans.removeAt(index);
    // });
  }

  void _applyCoupon() {
    if (_couponController.text.isNotEmpty) {
      coupounAPIData();
    }
  }

  /////
  ///
  ///

  void callRagerPayment() async {
    final double numPrice = double.tryParse(finalPrice) ?? 0.0;
    if (numPrice <= 0) {
      callpaymentVeifyAPI("FREE_SUB_${DateTime.now().millisecondsSinceEpoch}");
      return;
    }

    final int amountInPaise = (numPrice * 100).round();
    String contact = userData["phone_number"] ?? userData["phone"] ?? '';
    String email = userData["email"] ?? '';

    var options = {
      'key': Config.razorpayKey,
      'amount': amountInPaise,
      'name': 'Go buddy',
      'description': 'Subscription Payment',
      'currency': 'INR',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
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
      dynamic subscriptionIds = plans.map((sub) => sub["subscription_id"]).toList();
      String commaSeparatedSub= subscriptionIds.join(', ');

    if (internet) {         
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.subPayment, {
        "user_id": userData["user_id"] ?? "",
        "coupon": _couponController.text,
        "amount":finalPrice,
      
        "saving_amount": _appliedCouponAmount,
        "payment_id": paymentid,
        "subscription_ids":commaSeparatedSub
      }).then((value) async {
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
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(Config.getActiveSubscriptionsRouteName, (route) => false);
                });

                return const ReferralDialog(
                  title: "Payment Successful",
                  subtitle: "Thank You for purchasing the subscription.",
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

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: deviceWidth * 0.05,
              vertical: deviceHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: deviceHeight * 0.05,
                        width: deviceHeight * 0.05,
                        decoration: BoxDecoration(
                          color: const Color(0xFF65B741),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: deviceWidth * 0.04),
                    const Text(
                      "Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: deviceHeight * 0.02),

                // Plans List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];

                    var data = plans[index]["package"];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title & Subtitle
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plans[index]["category"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                plans[index]["subscription"],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          // Delete & Price
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => removePlan(index),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "₹${plans[index]["package"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Add More Plans
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, Config.createPackageRouteName);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          "Add More Plans",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: deviceHeight * 0.02),

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
                                        borderRadius: BorderRadius.circular(10),
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
                                color: _isCouponApplied ? Colors.green : null,
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

                SizedBox(height: deviceHeight * 0.02),

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

                SizedBox(height: deviceHeight * 0.02),

                // Bottom Pay Button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹ $totalPrice",
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
