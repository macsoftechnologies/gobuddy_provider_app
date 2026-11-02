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

  List<Map<String, dynamic>> selectedPlans = [];
  bool _isDataLoaded = false;

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

    if (args != null && !_isDataLoaded) {
      _isDataLoaded = true;
      if (args['all_plans'] != null) {
        final list = args['all_plans'];
        if (list is List) {
          selectedPlans = list.map((e) {
            if (e is String) return jsonDecode(e) as Map<String, dynamic>;
            return Map<String, dynamic>.from(e as Map);
          }).toList();
        }
      } else if (args['all-data'] != null) {
        final data = args['all-data'];
        final map = data is String
            ? jsonDecode(data) as Map<String, dynamic>
            : Map<String, dynamic>.from(data as Map);
        selectedPlans = [map];
      } else {
        // Fallback: single plan passed from change_prices (Renew / Upgrade flow)
        final pAmt = args['selectedPackage']?['amount'] ??
            args['selectedPackage']?['package_amount'] ??
            args['package_amount'] ??
            args['amount'] ??
            '0';
        final pVal = args['selectedPackage']?['jobs'] ??
            args['selectedPackage']?['package_value'] ??
            args['package_value'] ??
            args['jobs'] ??
            '0';
        final pType = args['package_type'] ?? 'jobs';
        final planName = args['plan']?['plan'] ?? args['subscription'] ?? 'Subscription Plan';

        selectedPlans = [{
          'category_id': args['category_id'] ?? '',
          'category': args['category'] ?? '',
          'subscription': planName,
          'package_type': pType,
          'package_value': pVal.toString(),
          'package_amount': pAmt.toString(),
          'services': args['services'] ?? [],
          'addons': args['addons'] ?? [],
          'subscription_id': args['subscription_id'],
        }];
      }
    }
  }

  @override
  void dispose() {
    couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  double get totalAmount {
    double total = 0.0;
    for (var plan in selectedPlans) {
      final pAmt = double.tryParse(plan['package_amount']?.toString() ?? '0') ?? 0.0;
      total += pAmt;
      // Add-on prices are customer rates, not subscription plan cost
      //
      //
      //
    }
    return total;
  }

  double get gstAmount => (totalAmount * 0.18);

  double get toPay => (totalAmount + gstAmount - couponDiscount).clamp(0, double.infinity);

  void _addMorePlans() {
    Navigator.pushNamed(
      context,
      Config.createPackageRouteName,
      arguments: {
        'existing_plans': selectedPlans,
      },
    );
  }

  void _confirmRemovePlan(int index) {
    if (index < 0 || index >= selectedPlans.length) return;
    final plan = selectedPlans[index];
    final title = (plan['category_name'] != null && plan['category_name'].toString().isNotEmpty)
        ? "${plan['category_name']} - ${plan['subscription']}"
        : "${plan['subscription']}";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text("Remove $title from your selected plans?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _removePlan(index);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _removePlan(int index) {
    if (index >= 0 && index < selectedPlans.length) {
      setState(() {
        selectedPlans.removeAt(index);
        if (selectedPlans.isEmpty) {
          couponDiscount = 0;
          appliedCouponCode = null;
          couponController.clear();
          couponError = null;
        } else if (appliedCouponCode != null) {
          _applyCoupon();
        }
      });
    }
  }

  Future<void> _applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) {
      setState(() => couponError = "Please enter a coupon code");
      return;
    }

    if (totalAmount <= 0) {
      setState(() => couponError = "Please add at least one plan before applying a coupon");
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
        "price": totalAmount.toStringAsFixed(2),
      });

      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : (response as Map<String, dynamic>);

      if (jsonResponse["status"] == "valid" || jsonResponse["status"] == true) {
        double discountFromApi = 0;
        if (jsonResponse["coupon_amount"] != null) {
          discountFromApi = double.tryParse(jsonResponse["coupon_amount"].toString()) ?? 0;
        } else if (jsonResponse["saving_amount"] != null) {
          discountFromApi = double.tryParse(jsonResponse["saving_amount"].toString()) ?? 0;
        } else if (jsonResponse["discount"] != null) {
          discountFromApi = double.tryParse(jsonResponse["discount"].toString()) ?? 0;
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

  void _removeCoupon() {
    setState(() {
      appliedCouponCode = null;
      couponDiscount = 0;
      couponController.clear();
      couponError = null;
    });
  }

  // ─────────────────────────────────────────────────────
  // Subscription confirmation API call (creates all selected plans)
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

    List<String> createdSubIds = [];
    List<String> failedPlanErrors = [];

    for (var plan in selectedPlans) {
      try {
        final response = await Repository.postApiRawService(
          EndPoints.addSubscriptionProvider,
          {
            "provider_id": userData['user_id'] ?? "",
            "category_id": plan['category_id'] ?? "",
            "subscription": plan['subscription'] ?? "",
            "package_type": plan['package_type'] ?? "",
            "package_value": plan['package_value'] ?? "",
            "package_amount": plan['package_amount'] ?? "",
            "services": plan['services'] ?? [],
            "addons": plan['addons'] ?? [],
            "subscription_id": plan['subscription_id'] ?? "",
            "is_upgrade": (plan['subscription_id'] != null && plan['subscription_id'].toString().isNotEmpty) ? 1 : 0,
          },
        );

        print("ADD SUBSCRIPTION RAW RESPONSE: $response");

        Map<String, dynamic> jsonResponse;
        if (response is String) {
          jsonResponse = json.decode(response);
        } else {
          jsonResponse = response as Map<String, dynamic>;
        }

        if (jsonResponse["status"] == true) {
          final subSuccess = GetSubscriptionSuccessModel.fromJson(jsonResponse);
          setState(() {
            pushintoSubscriptionSuccess = subSuccess;
          });

          final String subId = subSuccess.subscriptionId?.toString() ?? "";
          if (subId.isNotEmpty) {
            createdSubIds.add(subId);
          }
        } else {
          final planName = plan['category_name'] ?? plan['subscription'];
          failedPlanErrors.add("$planName: ${jsonResponse['message'] ?? 'Failed'}");
        }
      } catch (e) {
        print("_addProviderSubscription error: $e");
        final planName = plan['category_name'] ?? plan['subscription'];
        failedPlanErrors.add("$planName: $e");
      }
    }

    if (!mounted) return;

    if (createdSubIds.isNotEmpty) {
      final String commaSeparatedIds = createdSubIds.join(",");
      if (paymentId.isNotEmpty) {
        await _recordSubscriptionPayment(
          paymentId: paymentId,
          subscriptionId: commaSeparatedIds,
        );
      } else {
        _closeProcessingDialogIfOpen();
        _showPaymentSuccessDialog();
      }
    } else {
      _closeProcessingDialogIfOpen();
      UtilClass.showAlertDialog(
        context: context,
        message: failedPlanErrors.isNotEmpty
            ? "Subscription creation failed:\n${failedPlanErrors.join('\n')}"
            : "Failed to confirm subscriptions. Please try again.",
      );
    }
  }

  // ─────────────────────────────────────────────────────
  // Record payment order on backend with comma-separated subscription IDs
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
    if (selectedPlans.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "No plans selected. Please add at least one plan to continue.",
      );
      return;
    }

    for (var plan in selectedPlans) {
      final services = (plan['services'] as List<dynamic>?) ?? [];
      if (services.isEmpty) {
        UtilClass.showAlertDialog(
          context: context,
          message: "No services selected for ${plan['category_name'] ?? plan['subscription']}. Please configure services before paying.",
        );
        return;
      }
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
      UtilClass.showAlertDialog(
          context: context, message: "Unable to open payment screen: $e");
    }
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint(
        "RAZORPAY PAYMENT FAILED — code: ${response.code}, message: ${response.message}");
    if (!mounted) return;
    UtilClass.showAlertDialog(
        context: context, message: "Payment Failed please try again");
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
                      _buildPlansList(),
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
  // Plans list (supports multiple plans in cart)
  // ─────────────────────────────────────────────────────
  Widget _buildPlansList() {
    if (selectedPlans.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: _cardDecoration(),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              const Text(
                "No subscription plans in cart",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                "Tap 'Add More Plans' below to choose a category plan",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(selectedPlans.length, (index) {
        final plan = selectedPlans[index];
        final catName = plan['category_name']?.toString() ?? "";
        final subName = plan['subscription']?.toString() ?? "Plan";
        final pkgType = plan['package_type']?.toString() ?? "";
        final pkgVal = plan['package_value']?.toString() ?? "";
        final pkgAmt = double.tryParse(plan['package_amount']?.toString() ?? '0') ?? 0.0;
        final servicesList = (plan['services'] as List<dynamic>?) ?? [];
        final addonsList = (plan['addons'] as List<dynamic>?) ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (catName.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              catName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          subName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmRemovePlan(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                    tooltip: "Remove Plan",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
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
                        Text(pkgType,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(pkgVal, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Text(
                      "₹${pkgAmt.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              if (servicesList.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Services (${servicesList.length})",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...servicesList.map((service) {
                  final String sName = (service['service_name'] ??
                          service['title'] ??
                          service['name'] ??
                          '')
                      .toString()
                      .trim();
                  final String displayServiceName = sName.isNotEmpty
                      ? sName
                      : "Service #${service['service_id']}";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayServiceName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "₹${service['price']}${service['discount'] != null && service['discount'].toString() != '0' ? ' (${service['discount']} ${service['type'] ?? ''} off)' : ''}",
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (addonsList.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  "Add-ons (${addonsList.length})",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...addonsList.map((addon) {
                  final String aName = (addon['addon_name'] ??
                          addon['addon_service'] ??
                          addon['title'] ??
                          addon['name'] ??
                          '')
                      .toString()
                      .trim();
                  final String displayAddonName = aName.isNotEmpty
                      ? aName
                      : "Addon #${addon['addon_id']}";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(displayAddonName, style: const TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        Text("₹${addon['price']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      }),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Coupon \"$appliedCouponCode\" applied — you saved ₹${couponDiscount.toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFF3AAD41), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      "Remove",
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
