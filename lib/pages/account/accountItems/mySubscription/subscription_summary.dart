import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/boras_touch_models/subscription_success_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ProviderSubscriptionSummary extends StatefulWidget {
  const ProviderSubscriptionSummary({super.key});

  @override
  State<ProviderSubscriptionSummary> createState() =>
      _ProviderSubscriptionSummaryState();
}

class _ProviderSubscriptionSummaryState
    extends State<ProviderSubscriptionSummary> {
  double deviceHeight = 0;
  double deviceWidth = 0;
    dynamic userData = {};

  Map<String, dynamic>? receivedData;

  String subscription = "";
  String packageType = "";
  String packageValue = "";
  double packageAmount = 0;
  String? categoryId;

  List services = [];
  List addons = [];

  final TextEditingController couponController = TextEditingController();

  bool isApplyingCoupon = false;
  double couponDiscount = 0;
  String? couponError;
  String? appliedCouponCode;
  GetSubscriptionSuccessModel? pushintoSubscriptionSuccess;

  late final Razorpay _razorpay = Razorpay();

  // ✅ tracks whether the "Confirming your subscription..." dialog
  // is currently on screen, so we know exactly when/whether to pop it
  bool _isProcessingDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
      var userDataValue = Preferences.getUserDetails();
  if (userDataValue != null) {
    userData = json.decode(userDataValue);
  }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && receivedData == null) {
      final data = args['all-data'];

      if (data is String) {
        receivedData = jsonDecode(data);
      } else {
        receivedData = Map<String, dynamic>.from(data);
      }

      subscription = receivedData?['subscription'] ?? '';
      packageType = receivedData?['package_type'] ?? '';
      packageValue = receivedData?['package_value'] ?? '';
      categoryId = receivedData?['category_id'] ?? '';

      packageAmount = double.tryParse(
            receivedData?['package_amount'].toString() ?? '0',
          ) ??
          0;

      services = receivedData?['services'] ?? [];
      addons = receivedData?['addons'] ?? [];
    }
  }

  @override
  void dispose() {
    couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  double get totalAmount {
    double total = packageAmount;
    for (var addon in addons) {
      total += double.tryParse(addon['price'].toString()) ?? 0;
    }
    return total;
  }

  double get gstAmount => (totalAmount * 0.18);

  double get toPay => (totalAmount + gstAmount - couponDiscount).clamp(0, double.infinity);

  void _addMorePlans() {
    Navigator.pushNamed(context, Config.createPackageRouteName);
  }

  Future<void> _applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) {
      setState(() => couponError = "Please enter a coupon code");
      return;
    }

    if (!await UtilClass.checkInternet()) {
      setState(() => couponError = "No Internet Connection");
      return;
    }

    setState(() {
      isApplyingCoupon = true;
      couponError = null;
    });

    try {
      final response = await Repository.postApiService(EndPoints.coupounApi, {
        "user_id": userData['user_id'] ?? "",
        "coupon": code,
      });

      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : (response as Map<String, dynamic>);

      if (jsonResponse["status"] == "valid" || jsonResponse["status"] == true) {
        double discountFromApi = 0;
        if (jsonResponse["discount"] != null) {
          discountFromApi = double.tryParse(jsonResponse["discount"].toString()) ?? 0;
        } else if (jsonResponse["saving_amount"] != null) {
          discountFromApi = double.tryParse(jsonResponse["saving_amount"].toString()) ?? 0;
        } else if (jsonResponse["amount"] != null) {
          discountFromApi = double.tryParse(jsonResponse["amount"].toString()) ?? 0;
        }

        setState(() {
          couponDiscount = discountFromApi;
          appliedCouponCode = code;
          couponError = null;
        });
      } else {
        setState(() {
          couponError = jsonResponse["message"] ?? "Invalid or expired coupon code";
          couponDiscount = 0;
          appliedCouponCode = null;
        });
      }
    } catch (e) {
      setState(() => couponError = "Failed to verify coupon: $e");
    } finally {
      setState(() => isApplyingCoupon = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // Subscription confirmation API call
  // ─────────────────────────────────────────────────────
  Future<void> _addProviderSubscription(String paymentId) async {
    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      _closeProcessingDialogIfOpen();
      if (!mounted) return;
      UtilClass.showAlertDialog(
          context: context, message: "No Internet Connection");
      return;
    }
    try {
      final response = await Repository.postApiRawService(
        EndPoints.addSubscriptionProvider,
        {
          "provider_id": userData['user_id'] ?? "", 
          "category_id": categoryId ?? "",
          "subscription": subscription,
          "package_type": packageType,
          "package_value": packageValue,
          "package_amount": packageAmount,
          "services": services,
          "addons": addons,
        },
      );

      print("ADD SUBSCRIPTION RAW RESPONSE: $response");

      Map<String, dynamic> jsonResponse;
      if (response is String) {
        jsonResponse = json.decode(response);
      } else {
        jsonResponse = response as Map<String, dynamic>;
      }

      if (!mounted) return;

      if (jsonResponse["status"] == true) {
        final subSuccess = GetSubscriptionSuccessModel.fromJson(jsonResponse);
        setState(() {
          pushintoSubscriptionSuccess = subSuccess;
        });

        final String subId = subSuccess.subscriptionId?.toString() ?? "";
        if (paymentId.isNotEmpty && subId.isNotEmpty) {
          await _recordSubscriptionPayment(
            paymentId: paymentId,
            subscriptionId: subId,
          );
        } else {
          _closeProcessingDialogIfOpen();
          _showPaymentSuccessDialog();
          if (jsonResponse['message'] != null) {
            UtilClass.showAlertDialog(context: context, message: "${jsonResponse['message']}");
          }
        }
      } else {
        _closeProcessingDialogIfOpen();
        UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse["message"] ?? "Subscription failed",
        );
      }
    } catch (e) {
      print("_addProviderSubscription error: $e");
      _closeProcessingDialogIfOpen();
      if (!mounted) return;
      UtilClass.showAlertDialog(
          context: context,
          message: "Payment succeeded but confirming your subscription failed: $e");
    }
  }

  // ─────────────────────────────────────────────────────
  // Record payment order on backend
  // ─────────────────────────────────────────────────────
  Future<void> _recordSubscriptionPayment({
    required String paymentId,
    required String subscriptionId,
  }) async {
    try {
      final response = await Repository.postApiService(
        EndPoints.subPayment,
        {
          "user_id": userData['user_id'] ?? "",
          "coupon": appliedCouponCode ?? "",
          "amount": toPay.toStringAsFixed(0),
          "saving_amount": couponDiscount.toStringAsFixed(0),
          "payment_id": paymentId,
          "subscription_ids": subscriptionId,
        },
      );

      print("RECORD SUBSCRIPTION PAYMENT RAW RESPONSE: $response");
      _closeProcessingDialogIfOpen();
      if (!mounted) return;

      dynamic parsed = response is String ? json.decode(response) : response;
      if (parsed is Map && (parsed["status"] == "valid" || parsed["status"] == true || parsed["status"] == "success")) {
        _showPaymentSuccessDialog();
      } else {
        String msg = (parsed is Map && parsed["message"] != null)
            ? parsed["message"].toString()
            : "Subscription activated.";
        _showPaymentSuccessDialog();
        UtilClass.showAlertDialog(context: context, message: msg);
      }
    } catch (e) {
      print("_recordSubscriptionPayment error: $e");
      _closeProcessingDialogIfOpen();
      if (!mounted) return;
      _showPaymentSuccessDialog();
      UtilClass.showAlertDialog(
        context: context,
        message: "Subscription created successfully, but error saving payment details: $e",
      );
    }
  }

  void _proceedToPay() {
    if (services.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "No services selected for this subscription. Please go back and configure your services before paying.",
      );
      return;
    }
    if (toPay <= 0) {
      _showProcessingDialog();
      _addProviderSubscription("FREE_COUPON_APPLIED");
    } else {
      callRagerPayment();
    }
  }

  void callRagerPayment() {
    final int amountInPaise = (toPay * 100).round();

    String contact = userData["phone_number"] ?? userData["phone"] ?? "";
    String email = userData["email"] ?? "";

    var options = {
      'key': Config.razorpayKey,
      'amount': amountInPaise,
      'name': 'Go buddy',
      'description': 'Subscription Payment',
      'currency': 'INR',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay open error: $e");
      if (!mounted) return;
      if (Config.razorpayKey.startsWith("rzp_test_")) {
        _showTestPaymentFallback(
          reason: "Unable to open payment screen: $e",
          onSimulateSuccess: () {
            _showProcessingDialog();
            _addProviderSubscription("TEST_SUB_${DateTime.now().millisecondsSinceEpoch}");
          },
        );
      } else {
        UtilClass.showAlertDialog(
            context: context, message: "Unable to open payment screen: $e");
      }
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint(
        "RAZORPAY PAYMENT FAILED — code: ${response.code}, message: ${response.message}");
    if (!mounted) return;
    if (Config.razorpayKey.startsWith("rzp_test_")) {
      _showTestPaymentFallback(
        reason: "${response.message ?? 'Payment was cancelled or failed'}",
        onSimulateSuccess: () {
          _showProcessingDialog();
          _addProviderSubscription("TEST_SUB_${DateTime.now().millisecondsSinceEpoch}");
        },
      );
    } else {
      UtilClass.showAlertDialog(
          context: context, message: "Payment Failed please try again");
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
          "$reason\n\nYou are in Test Mode (using test key). Would you like to simulate successful payment to complete subscription testing?",
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
    debugPrint(
        "RAZORPAY PAYMENT SUCCESS — paymentId: ${response.paymentId}, orderId: ${response.orderId}, signature: ${response.signature}");

    _showProcessingDialog();
    _addProviderSubscription(response.paymentId ?? "");
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    if (!mounted) return;
    UtilClass.showAlertDialog(context: context, message: "${response.walletName}");
  }

  // ─────────────────────────────────────────────────────
  // "Confirming your subscription..." loading dialog
  // ─────────────────────────────────────────────────────
  void _showProcessingDialog() {
    if (!mounted || _isProcessingDialogOpen) return;
    _isProcessingDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Color(0xFF3AAD41)),
                SizedBox(height: 20),
                Text(
                  "Confirming your subscription...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _closeProcessingDialogIfOpen() {
    if (_isProcessingDialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isProcessingDialogOpen = false;
    }
  }

  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: pushintoSubscriptionSuccess == null && Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          Config.dashboardcRouteName,
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: deviceWidth * 0.05,
                      vertical: deviceHeight * 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlansCard(),
                      SizedBox(height: deviceHeight * 0.02),
                      _buildAddMorePlansButton(),
                      SizedBox(height: deviceHeight * 0.025),
                      _buildOffersCard(),
                      SizedBox(height: deviceHeight * 0.025),
                      _buildToPayCard(),
                      SizedBox(height: deviceHeight * 0.02),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          deviceWidth * 0.05, deviceHeight * 0.015, deviceWidth * 0.05, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            if (pushintoSubscriptionSuccess != null) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                Config.dashboardcRouteName,
                (route) => false,
              );
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, Config.dashboardcRouteName);
            }
          },
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF7CB342), Color(0xFF3AAD41)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
        ),
        SizedBox(width: deviceWidth * 0.04),
        const Text(
          "Summary",
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // Plans card
  // ─────────────────────────────────────────────────────
  Widget _buildPlansCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subscription,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(packageType,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(packageValue, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Text(
                  "₹${packageAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          if (services.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("Services",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...services.map((service) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Service ID : ${service['service_id']}"),
                    const SizedBox(height: 5),
                    Text("Price : ₹${service['price']}"),
                    Text("Discount : ${service['discount']} (${service['type']})"),
                  ],
                ),
              );
            }).toList(),
          ],
          if (addons.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("Add-ons",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...addons.map((addon) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Addon ID : ${addon['addon_id']}"),
                    Text("₹${addon['price']}"),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  Widget _buildAddMorePlansButton() {
    return GestureDetector(
      onTap: _addMorePlans,
      child: Container(
        width: double.infinity,
        height: deviceHeight * 0.06,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3AAD41), width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Color(0xFF3AAD41), size: 20),
            SizedBox(width: 8),
            Text(
              "Add More Plans",
              style: TextStyle(
                  color: Color(0xFF3AAD41), fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  Widget _buildOffersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.local_offer_outlined, color: Color(0xFF3AAD41), size: 18),
            const SizedBox(width: 6),
            Text("Offers",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ]),
          const SizedBox(height: 10),
          const Text(
            "Enter coupon code  ( Optional )",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Enter Code",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: isApplyingCoupon ? null : _applyCoupon,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3AAD41)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: isApplyingCoupon
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3AAD41)))
                    : const Text("Apply",
                        style: TextStyle(color: Color(0xFF3AAD41), fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
          if (couponError != null) ...[
            const SizedBox(height: 8),
            Text(couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (appliedCouponCode != null) ...[
            const SizedBox(height: 8),
            Text(
              "Coupon \"$appliedCouponCode\" applied — you saved ₹${couponDiscount.toStringAsFixed(0)}",
              style: const TextStyle(color: Color(0xFF3AAD41), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  Widget _buildToPayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_outlined, color: Color(0xFF3AAD41), size: 18),
            const SizedBox(width: 8),
            Text("To pay",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            const Spacer(),
            Text(
              "₹${totalAmount.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ]),
          const SizedBox(height: 14),
          _dashedDivider(),
          const SizedBox(height: 14),
          _summaryRow("Plan Amount", totalAmount, isMuted: true),
          const SizedBox(height: 10),
          _summaryRow("GST (18%)", gstAmount, isMuted: true),
          if (couponDiscount > 0) ...[
            const SizedBox(height: 10),
            _summaryRow("Coupon Discount", -couponDiscount,
                isMuted: true, valueColor: const Color(0xFF3AAD41)),
          ],
          const SizedBox(height: 10),
          _summaryRow("To Pay (incl. GST)", toPay, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value,
      {bool isMuted = false, bool isBold = false, Color? valueColor}) {
    final String sign = value < 0 ? "-" : "";
    final double absValue = value.abs();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              color: isMuted ? Colors.grey.shade500 : Colors.black87,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500),
        ),
        Text(
          "$sign₹${absValue.toStringAsFixed(0)}",
          style: TextStyle(
              fontSize: 14,
              color: valueColor ?? (isMuted ? Colors.grey.shade500 : Colors.black87),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500),
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 5.0;
        final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
        return Flex(
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return Expanded(
              child: Container(
                color: Colors.grey.shade300,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 2),
              ),
            );
          }),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: deviceWidth * 0.05, vertical: deviceHeight * 0.018),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₹${toPay.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text("To be paid now", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          ElevatedButton(
            onPressed: _proceedToPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAD41),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Proceed to Pay",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  // ─────────────────────────────────────────────────────
  // ✅ "Payment Successful" dialog — matches the target design exactly:
  // soft green glow ring behind the check circle, and a
  // yellow→green gradient full-width "Ok" button.
  // ─────────────────────────────────────────────────────
  void _showPaymentSuccessDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Soft glow ring behind the check circle
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3AAD41).withOpacity(0.12),
                        ),
                      ),
                      Container(
                        height: 64,
                        width: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3AAD41),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  "Payment Successful",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Thank you for purchasing the subscription. You are all set to receive jobs and start working.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB7C53A), Color(0xFF3AAD41)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Config.getActiveSubscriptionsRouteName,
                            (route) => false,
                          );
                        },
                        child: const Center(
                          child: Text(
                            "Ok",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
      },
    );
  }
}