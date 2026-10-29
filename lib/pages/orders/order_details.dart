import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import '../../models/cancel_reasons.dart';
import '../../components/button.dart';
import '../../utils/config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final dynamic order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Map<String, dynamic> orderData;
  dynamic orderDetails = {};
  final TextEditingController _orderCodeController = TextEditingController();
  int _selectedPaymentIndex = 0;
  bool _isVerified = false; // 🔹 New flag for Verify button state
  bool _isloaderservice = false;
  // New variables for extra service charge

  ////////services
  late Map<String, dynamic> serviceData;
  // ---------- SERVICES LIST (MULTIPLE SERVICE ORDERS) ----------
  List<dynamic> servicesData = [];

  int selectedServiceIndex = 0;
  dynamic userData = {};
  List<Map<String, dynamic>> _extraCharges = [];
  double _extraServiceTotal = 0.0;

  final Map<String, dynamic> cancelReasonsJson = {
    "cancelreasons": [
      {"id": "1", "reason": "Price Issue"},
      {"id": "2", "reason": "Lack of required skills"},
      {"id": "3", "reason": "Risky work"},
      {"id": "4", "reason": "Customer behavior is not good"},
    ],
  };

  String get resolvedOrderId =>
      (widget.order["job_calender_id"] ?? widget.order["id"] ?? widget.order["order_id"] ?? "").toString();

  double get travelingTotal {
    double fee = _parseDouble(orderDetails["travelling_charges"] ??
        orderDetails["travelingCharge"] ??
        orderDetails["traveling_charge"] ??
        0);
    if (fee == 0) {
      for (var item in servicesData) {
        fee += _parseDouble(item["travelingCharge"] ?? item["travelling_charges"]);
      }
    }
    return fee;
  }

  GetCancelOrderReasons? cancelReasonsData;

  // ------------------ IMAGE PICKER ------------------
  final ImagePicker picker = ImagePicker();

  Future<void> pickServiceImage(bool isBefore) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isBefore) {
          servicesData[selectedServiceIndex]["beforeImages"].add(
            File(pickedFile.path),
          );
        } else {
          servicesData[selectedServiceIndex]["afterImages"].add(
            File(pickedFile.path),
          );
        }
      });
    }
  }

  /////////services end
  ///
  Future<void> makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error making call: $e");
    }
  }

  Future<void> sendSMS(String phoneNumber, [String? body]) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: body != null ? {'body': body} : null,
      );
      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
        final fallbackUri = Uri.parse("sms:$phoneNumber?body=${Uri.encodeComponent(body ?? '')}");
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error sending SMS: $e");
    }
  }

  Map<String, dynamic> customerProfile = {};

  Future<void> sendEmail(String email, [String? subject, String? body]) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {
          if (subject != null) 'subject': subject,
          if (body != null) 'body': body,
        },
      );
      if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
        final fallbackUri = Uri.parse("mailto:$email?subject=${Uri.encodeComponent(subject ?? '')}&body=${Uri.encodeComponent(body ?? '')}");
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching email: $e");
    }
  }

  void _fetchCustomerProfile(String customerId) async {
    if (customerId.isEmpty) return;
    try {
      final response = await Repository.postApiService(EndPoints.profile, {
        "user_id": customerId,
      });
      dynamic parsed = response is String ? json.decode(response) : response;
      if (parsed != null && (parsed["status"] == "valid" || parsed["status"] == true) && parsed["profile"] is Map) {
        if (mounted) {
          setState(() {
            customerProfile = Map<String, dynamic>.from(parsed["profile"]);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching customer profile: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // Simulating fetched JSON data
    _getCancelReasons();
    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    callOrdersPI();
  }

  void _getCancelReasons() async {
    try {
      final response = await Repository.getApiService(
        EndPoints.getProviderCancelReasons,
      );
      final dynamic parsed =
          response is String ? json.decode(response) : response;
      if (parsed is Map<String, dynamic> &&
          (parsed["status"] == "valid" || parsed["status"] == true)) {
        cancelReasonsData = GetCancelOrderReasons.fromJson(parsed);
      } else {
        cancelReasonsData = GetCancelOrderReasons.fromJson(cancelReasonsJson);
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Cancel reasons API error: $e");
      cancelReasonsData = GetCancelOrderReasons.fromJson(cancelReasonsJson);
      if (mounted) setState(() {});
    }
  }

  void submitOrdersPI() async {
    print(_extraCharges);

    final List<dynamic> labels = _extraCharges
        .map((city) => city["description"])
        .toList();
    final List<dynamic> amounts = _extraCharges
        .map((city) => city["amount"])
        .toList();
    var finalData = {
      "job_calender_id": resolvedOrderId,
      "payment_type": _selectedPaymentIndex == 0 ? "phonepay" : "cash",
      "travelling_charges": travelingTotal > 0 ? travelingTotal.toStringAsFixed(0) : "0",
      "add_extra_charges": amounts,
      "reason_for_extracharges": labels,
    };


    List<dynamic> finalServices = [];
    for (int i = 0; i < servicesData.length; i++) {
      List<dynamic> beforeImages = servicesData[i]["beforeImages"] ?? [];
      List<dynamic> afterImages = servicesData[i]["afterImages"] ?? [];
      List<MultipartFile> multipartFilesbefore = [];
      List<MultipartFile> multipartFilesafter = [];
      if (beforeImages.isNotEmpty) {
        multipartFilesbefore = beforeImages.map((image) {
          String fileName = image.path.split('/').last;
          return MultipartFile.fromFileSync(
            image.path,
            filename: "before$fileName",
          );
        }).toList();
      }

      if (afterImages.isNotEmpty) {
        multipartFilesafter = afterImages.map((image) {
          String fileName = image.path.split('/').last;
          return MultipartFile.fromFileSync(
            image.path,
            filename: "after$fileName",
          );
        }).toList();
      }

      List<dynamic> combinedList = [
        ...multipartFilesbefore,
        ...multipartFilesafter,
      ];

      if (combinedList.isNotEmpty) {
        var formData = FormData.fromMap({
          "provider_id": userData["user_id"],
          "images[]": combinedList,
          "service_id": servicesData[i]["service_id"],
          'order_id': resolvedOrderId,
        });

        finalServices.add(
          Repository.postimagesApiService(EndPoints.addImages, formData),
        );
      }
    }

    var internet = await UtilClass.checkInternet();
    if (internet) {
      if (finalServices.isNotEmpty) {
        // ignore: use_build_context_synchronously
        UtilClass.showProgress(context: context);
        try {
          List<dynamic> resultsd = await Future.wait(
            finalServices.cast<Future<dynamic>>(),
          );
          print("Images uploaded: $resultsd");
        } catch (e) {
          print("Image upload warning: $e");
        }
      }

      print("completed");
      //  UtilClass.showAlertDialog(context: context, message:"uplaoded");

      UtilClass.showProgress(context: context);

      await Repository.postApiServiceWithJson(
        EndPoints.submitDetails,
        finalData,
      ).then((value) async {
        UtilClass.hideProgress();

        dynamic parsed = value;
        try {
          if (parsed["status"] == "success" || parsed["status"] == "valid") {
            Navigator.pushNamedAndRemoveUntil(
              // ignore: use_build_context_synchronously
              context,
              Config.myOrdersRouteName,
              (route) => false,
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              UtilClass.showAlertDialog(
                // ignore: use_build_context_synchronously
                context: context,
                message: parsed["message"] ?? "Job completed successfully!",
              );
            });
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
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void _syncChargesToBackend() async {
    final List<dynamic> labels = _extraCharges
        .map((city) => city["description"])
        .toList();
    final List<dynamic> amounts = _extraCharges
        .map((city) => city["amount"])
        .toList();
    var syncData = {
      "job_calender_id": resolvedOrderId,
      "travelling_charges": travelingTotal > 0 ? travelingTotal.toStringAsFixed(0) : "0",
      "add_extra_charges": amounts,
      "reason_for_extracharges": labels,
    };
    try {
      await Repository.postApiServiceWithJson(
        EndPoints.updateCharges,
        syncData,
      );
    } catch (e) {
      debugPrint("Error syncing extra charges: $e");
    }
  }

  void callOrdersPI() async {
    dynamic resolveId(dynamic val) {
      if (val == null) return null;
      final s = val.toString().trim();
      if (s.isEmpty || s == "0" || s == "null" || s == "undefined") return null;
      return s;
    }

    final dynamic orderId = resolveId(widget.order["job_calender_id"]) ??
        resolveId(widget.order["id"]) ??
        resolveId(widget.order["order_id"]);

    final providerId = (userData["user_id"] ?? userData["id"] ?? "").toString().trim();
    final initialCustId = (widget.order["user_id"] ?? widget.order["customer_id"] ?? "").toString().trim();
    if (initialCustId.isNotEmpty && initialCustId != providerId) {
      _fetchCustomerProfile(initialCustId);
    }

    if (orderId == null || orderId.toString().isEmpty || orderId.toString() == "0") {
      debugPrint("Warning: No valid order ID in widget.order: ${widget.order}");
      setState(() {
        orderDetails = Map<String, dynamic>.from(widget.order);
        _isloaderservice = true;
      });
      return;
    }

    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.orderDetails, {
        "order_id": orderId,
      }).then((value) async {
        UtilClass.hideProgress();

        dynamic parsed;
        try {
          parsed = value is String ? json.decode(value) : value;
        } catch (_) {
          parsed = value;
        }

        try {
          if (parsed != null && (parsed["status"] == true || parsed["status"] == "valid")) {
            final data = parsed["data"] is Map ? Map<String, dynamic>.from(parsed["data"]) : <String, dynamic>{};
            final services = (data["services"] is List) ? List<dynamic>.from(data["services"]) : <dynamic>[];
            for (int i = 0; i < services.length; i++) {
              if (services[i] is Map) {
                services[i]["beforeImages"] = [];
                services[i]["afterImages"] = [];
                services[i]["is_photos_upload"] = false;
              }
            }

            final loadedExtra = (data["extra_charges"] is List) ? List<dynamic>.from(data["extra_charges"]) : [];
            if (loadedExtra.isNotEmpty && _extraCharges.isEmpty) {
              _extraCharges = loadedExtra.map((c) => {
                'amount': _parseDouble(c["extra_charge_amount"] ?? c["amount"]),
                'description': (c["reason"] ?? c["description"] ?? "Extra Charge").toString(),
              }).toList();
              _extraServiceTotal = _extraCharges.fold(0.0, (sum, item) => sum + _parseDouble(item['amount']));
            }

            setState(() {
              orderDetails = data;
              servicesData = services;
              if (services.isNotEmpty) {
                serviceData = services[0];
              }
              _isloaderservice = true;
            });

            final custId = (data["user_id"] ?? widget.order["user_id"] ?? data["customer_id"] ?? widget.order["customer_id"] ?? "").toString().trim();
            if (custId.isNotEmpty && custId != providerId) {
              _fetchCustomerProfile(custId);
            }
          } else {
            setState(() {
              orderDetails = Map<String, dynamic>.from(widget.order);
              _isloaderservice = true;
            });
          }
        } catch (e) {
          print(e);
          setState(() {
            orderDetails = Map<String, dynamic>.from(widget.order);
            _isloaderservice = true;
          });
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void callVerifyAPI(code) async {
    if (!_isOrderAccepted()) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Please accept the order first before verifying customer code.",
      );
      return;
    }
    final codeStr = code?.toString().trim() ?? "";
    if (codeStr.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Please enter the verification code provided by the customer.",
      );
      return;
    }

    final orderId = orderDetails["id"] ?? widget.order["id"] ?? widget.order["job_calender_id"];
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.verifyCode, {
        "order_id": orderId,
        "code": codeStr,
      }).then((value) async {
        UtilClass.hideProgress();

        dynamic parsed;
        try {
          parsed = value is String ? json.decode(value) : value;
        } catch (_) {
          parsed = value;
        }

        try {
          if (parsed != null && (parsed["status"] == "valid" || parsed["status"] == true || parsed["status"] == "success")) {
            setState(() {
              _isVerified = true;
            });
            UtilClass.showAlertDialog(
              // ignore: use_build_context_synchronously
              context: context,
              message: "Order Code Verified Successfully!",
            );
          } else {
            // ignore: use_build_context_synchronously
            UtilClass.showAlertDialog(
              // ignore: use_build_context_synchronously
              context: context,
              message: (parsed is Map ? parsed["message"] : null) ?? "Invalid order code. Please check with customer.",
            );
          }
        } catch (e) {
          print(e);
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void callCancelAPI(text) async {
    print(widget.order);
    // _showCancelRequestPopup(context);
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      final resolvedOrderId = widget.order["job_calender_id"] ?? widget.order["id"] ?? widget.order["order_id"];
      await Repository.postApiService(EndPoints.cancelOrders, {
        "job_calender_id": resolvedOrderId,
        'cancel_reason': text,
      }).then((value) async {
        UtilClass.hideProgress();

        dynamic parsed = await json.decode(value);
        try {
          if (parsed["status"] == 'valid') {
            _showCancelRequestPopup(context);
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
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  // Helper method to safely convert dynamic values to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // final totalAmount = _parseDouble(orderData["price"]) +
    //     _parseDouble(orderData["travelingCharge"]) +
    //     _extraServiceTotal;
    ////ser
    ///
    ///
    ///
    ///if
    ///
    ///
    ///
    ///

    double servicesTotal = 0;
    double discountTotal = 0;
    for (var item in servicesData) {
      final q = item["quantity"] ?? item["qty"] ?? orderDetails["quantity"] ?? widget.order["quantity"] ?? 1;
      final qInt = int.tryParse(q.toString()) ?? 1;
      final qty = qInt > 0 ? qInt : 1;
      servicesTotal += _parseDouble(item["price"]) * qty;
      discountTotal += _parseDouble(item["discount"]);
    }
    if (discountTotal <= 0) {
      discountTotal = _parseDouble(orderDetails["discount"] ??
          orderDetails["coupon_amount"] ??
          widget.order["discount"] ??
          widget.order["coupon_amount"] ??
          "0");
    }

    final netServicesTotal = (servicesTotal - discountTotal).clamp(0.0, double.infinity);
    final totalAmount = netServicesTotal + _extraServiceTotal + travelingTotal;
    //ser end

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(
                context,
                Config.dashboardcRouteName,
              );
            }
          },
        ),
      ),
      body: _isloaderservice
          ? SingleChildScrollView(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderCard(size),
                  SizedBox(height: size.height * 0.02),
                  _buildCustomerDetails(size),
                  SizedBox(height: size.height * 0.02),
                  _buildIssueButton(size),
                  SizedBox(height: size.height * 0.02),

                  //serv
                  // ---------------- SERVICE TABS ----------------
                  Text(
                    'Order Have ${servicesData.length} Services',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,

                      fontSize: size.width * 0.045,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildServiceTabs(size), // servicesData.length

                          const SizedBox(height: 20),

                          // ---------------- SELECTED SERVICE CARD ----------------
                          _buildSelectedServiceCard(size),

                          const SizedBox(height: 25),

                          Visibility(
                            visible: _canPerformServiceActions(),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildUploadImageTitle(size),
                            ),
                          ),

                          const SizedBox(height: 15),
                          Visibility(
                            visible: _canPerformServiceActions(),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _imageUploadSection(size),
                            ),
                          ),

                          const SizedBox(height: 15),

                          _buildActionButtons(size),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //old price
                  _buildPriceDetails(size, totalAmount),
                  SizedBox(height: size.height * 0.03),
                  Visibility(
                    visible: _canPerformServiceActions(),
                    child: GradientButton(
                      onPressed: () {
                        // Navigator.of(context).pushReplacementNamed(
                        //   Config.jobCalendarRouteName,
                        // );
                        if (!_isVerified) {
                          UtilClass.showAlertDialog(
                            // ignore: use_build_context_synchronously
                            context: context,
                            message: "Code verification not completed",
                          );
                          return;
                        }
                        _showPaymentConfirmationDialog(context, totalAmount);
                      },
                      child: Text(
                        'Submit Details',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(),
    );
  }

  void _showPaymentConfirmationDialog(BuildContext context, double totalAmount) {
    final paymentMethodName = _selectedPaymentIndex == 0 ? "Payment via PhonePe (UPI)" : "By hand cash";
    final paymentIcon = _selectedPaymentIndex == 0 ? Icons.qr_code_2 : Icons.payments_outlined;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(paymentIcon, size: 40, color: Colors.green.shade700),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Confirm Payment Collection",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Payment Mode:", style: TextStyle(color: Colors.black54, fontSize: 13)),
                          Text(paymentMethodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total to Collect:", style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(
                            "₹${totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Have you collected ₹${totalAmount.toStringAsFixed(0)} from the customer?\nOnce completed, this order is permanently finalized.",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text("Cancel / Review", style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          submitOrdersPI();
                        },
                        child: const Text(
                          "Yes, Confirm",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //cancel order
  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: height * 0.03,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cancel Order?',
                  style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: height * 0.015),
                Text(
                  'Are you sure you want to cancel the order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: width * 0.3,
                      height: height * 0.055,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: width * 0.3,
                      height: height * 0.055,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCancelReasonSheet(context, cancelReasonsData);

                          // callCancelAPI("");
                          // ;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Yes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCancelRequestPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap OK
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.06,
              vertical: height * 0.03,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: width * 0.22,
                  width: width * 0.22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA726), // light orange background
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: width * 0.12,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025),
                Text(
                  "Cancel Request Submitted",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: height * 0.015),
                Text(
                  "Your cancellation request has been submitted. Sorry to see you go, one of our representatives will contact you to initiate cancellation or you can message/call us at 9347785705.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.04,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: height * 0.035),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigator.pop(context);
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pushNamed(
                          // ignore: use_build_context_synchronously
                          context,
                          Config.myOrdersRouteName,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A651), // green
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: height * 0.018),
                    ),
                    child: Text(
                      "Ok",
                      style: TextStyle(
                        fontSize: width * 0.045,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

  /// Order Card
  Widget _buildOrderCard(Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT COLUMN (Image + Status)
          // Column(
          //   children: [
          //     // ClipRRect(
          //     //   borderRadius: BorderRadius.circular(12),
          //     //   child: Image.network(
          //     //     orderData["imageUrl"],
          //     //     width: size.width * 0.2,
          //     //     height: size.width * 0.2,
          //     //     fit: BoxFit.cover,
          //     //   ),
          //     // ),
          //     SizedBox(height: size.height * 0.01),
          //     Container(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 12,
          //         vertical: 6,
          //       ),
          //       decoration: BoxDecoration(
          //         color: Colors.blue.shade100,
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: Text(
          //         orderDetails["status"],
          //         style: const TextStyle(
          //           color: Colors.blue,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          SizedBox(width: size.width * 0.04),

          /// RIGHT COLUMN (Details + Price + Icon)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Details",
                  style: TextStyle(
                    fontSize: size.width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Status: ${orderDetails["order_status"]}",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Order id: ${orderDetails["order_txn"]}",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Quantity: ${orderDetails["quantity"] ?? widget.order["quantity"] ?? 1}",
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: size.height * 0.005),

                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: size.width * 0.04,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        orderDetails["landmark"] ?? orderDetails["location"],
                        style: TextStyle(fontSize: size.width * 0.035),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.005),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: size.width * 0.04,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 4),
                    Text(
                      orderDetails["created_at"],
                      style: TextStyle(fontSize: size.width * 0.035),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.005),

                // Text(
                //   "Order id: ${orderData["orderId"]}",
                //   style: TextStyle(fontSize: size.width * 0.035, color: Colors.black87),
                // ),
                SizedBox(height: size.height * 0.01),

                /// PRICE & NAVIGATION ICON ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getOrderTotalDisplay(),
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Order Code Section with Verify Button Logic
  Widget _buildOrderCodeSection(Size size) {
    if (!_isOrderAccepted()) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Please accept this order first to enter customer verification code.",
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: size.width * 0.033,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter Order Code",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.045,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        Row(
          children: [
            Visibility(
              visible: _canPerformServiceActions(),
              child: Expanded(
                child: TextField(
                  controller: _orderCodeController,
                  decoration: InputDecoration(
                    hintText: "Enter code",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: size.width * 0.03),
            ElevatedButton(
              onPressed: _isVerified
                  ? null
                  : () {
                      callVerifyAPI(_orderCodeController.text);
                      print("Order Code: ${_orderCodeController.text}");
                    },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: _isVerified ? Colors.green : Colors.blue,
              ),
              child: Text(
                _isVerified ? "Verified" : "Verify",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _canPerformServiceActions() {
    final status = (orderDetails["order_status"] ?? widget.order["order_status"] ?? widget.order["status"] ?? "").toString().toLowerCase().trim();
    if (status.isEmpty) return true;
    return status == "scheduled" || status == "open" || status == "pending" || status == "in_progress" || status == "started" || status == "assigned";
  }

  bool _isOrderAccepted() {
    final status = (orderDetails["order_status"] ??
            widget.order["order_status"] ??
            widget.order["status"] ??
            "")
        .toString()
        .toLowerCase()
        .trim();
    if (status == "open") return false;
    final ordId = (orderDetails["id"] ?? widget.order["id"] ?? "").toString().trim();
    final calId = (orderDetails["job_calender_id"] ?? widget.order["job_calender_id"] ?? "").toString().trim();
    final txnId = (orderDetails["order_txn"] ?? widget.order["order_txn"] ?? "").toString().trim();
    if (Preferences.isOrderAcceptedLocally(ordId) ||
        Preferences.isOrderAcceptedLocally(calId) ||
        Preferences.isOrderAcceptedLocally(txnId) ||
        Preferences.isOrderStartedLocally(ordId) ||
        Preferences.isOrderStartedLocally(calId) ||
        Preferences.isOrderStartedLocally(txnId)) {
      return true;
    }
    return status == "pending" ||
        status == "accepted" ||
        status == "started" ||
        status == "in_progress" ||
        status == "ongoing" ||
        status == "completed";
  }

  String _getOrderTotalDisplay() {
    double servicesTotal = 0;
    for (var item in servicesData) {
      final q = item["quantity"] ?? item["qty"] ?? orderDetails["quantity"] ?? widget.order["quantity"] ?? 1;
      final qInt = int.tryParse(q.toString()) ?? 1;
      final qty = qInt > 0 ? qInt : 1;
      servicesTotal += _parseDouble(item["price"]) * qty;
    }
    final liveTotal = servicesTotal + _extraServiceTotal + travelingTotal;
    if (liveTotal > 0) {
      return "₹${liveTotal.toStringAsFixed(0)}";
    }
    for (final key in [
      "total_order_amount",
      "grand_total",
      "sub_total",
      "price",
      "doorstep_amount",
      "total_amount",
      "order_amount",
    ]) {
      final val = orderDetails[key] ?? widget.order[key];
      if (val != null && val.toString().trim().isNotEmpty && val.toString().trim() != "0") {
        return "₹${val.toString().trim()}";
      }
    }
    return "₹0";
  }

  String _getCustomerName() {
    final providerName = (userData["name"] ?? userData["user_name"] ?? "").toString().trim().toLowerCase();

    // Check customerProfile first (loaded directly by customer's user_id)
    if (customerProfile["name"] != null && customerProfile["name"].toString().trim().isNotEmpty) {
      final s = customerProfile["name"].toString().trim();
      if (s.toLowerCase() != "customer" && (providerName.isEmpty || s.toLowerCase() != providerName)) {
        return s;
      }
    }

    // Check customer-specific fields first
    for (final val in [
      customerProfile["name"],
      orderDetails["customer_name"],
      orderDetails["customer_fullname"],
      orderDetails["user_name"],
      (orderDetails["customer"] is Map ? (orderDetails["customer"]["name"] ?? orderDetails["customer"]["customer_name"]) : null),
      (orderDetails["user"] is Map ? (orderDetails["user"]["name"] ?? orderDetails["user"]["user_name"]) : null),
      (orderDetails["customer_details"] is Map ? (orderDetails["customer_details"]["name"] ?? orderDetails["customer_details"]["customer_name"]) : null),
      widget.order["customer_name"],
      widget.order["customer_fullname"],
      widget.order["user_name"],
      (widget.order["customer"] is Map ? (widget.order["customer"]["name"] ?? widget.order["customer"]["customer_name"]) : null),
      (widget.order["user"] is Map ? (widget.order["user"]["name"] ?? widget.order["user"]["user_name"]) : null),
      widget.order["client_name"],
      orderDetails["client_name"],
      orderDetails["name"],
      widget.order["name"],
    ]) {
      if (val != null && val.toString().trim().isNotEmpty) {
        final s = val.toString().trim();
        // Strictly ensure we don't display provider's own name as customer
        if (providerName.isNotEmpty && s.toLowerCase() == providerName) {
          continue;
        }
        if (s.toLowerCase() == "customer" || s.isEmpty) continue;
        return s;
      }
    }
    return "Customer";
  }

  String _getCustomerPhone() {
    final providerPhone = (userData["phone_number"] ?? userData["phone"] ?? userData["mobile"] ?? "").toString().trim();

    if (customerProfile["phone_number"] != null && customerProfile["phone_number"].toString().trim().isNotEmpty) {
      final s = customerProfile["phone_number"].toString().trim();
      if (providerPhone.isEmpty || s != providerPhone) {
        return s;
      }
    }
    if (customerProfile["mobile"] != null && customerProfile["mobile"].toString().trim().isNotEmpty) {
      final s = customerProfile["mobile"].toString().trim();
      if (providerPhone.isEmpty || s != providerPhone) {
        return s;
      }
    }

    for (final val in [
      customerProfile["phone_number"],
      customerProfile["mobile"],
      customerProfile["phone"],
      customerProfile["alternate_phone_number"],
      orderDetails["customer_phone"],
      orderDetails["customer_mobile"],
      orderDetails["user_phone"],
      orderDetails["user_mobile"],
      (orderDetails["customer"] is Map ? (orderDetails["customer"]["phone_number"] ?? orderDetails["customer"]["mobile"] ?? orderDetails["customer"]["phone"]) : null),
      (orderDetails["user"] is Map ? (orderDetails["user"]["phone_number"] ?? orderDetails["user"]["mobile"] ?? orderDetails["user"]["phone"]) : null),
      (orderDetails["customer_details"] is Map ? (orderDetails["customer_details"]["phone_number"] ?? orderDetails["customer_details"]["mobile"]) : null),
      widget.order["customer_phone"],
      widget.order["customer_mobile"],
      widget.order["user_phone"],
      (widget.order["customer"] is Map ? (widget.order["customer"]["phone_number"] ?? widget.order["customer"]["mobile"]) : null),
      (widget.order["user"] is Map ? (widget.order["user"]["phone_number"] ?? widget.order["user"]["mobile"]) : null),
      orderDetails["phone_number"],
      orderDetails["phone"],
      orderDetails["mobile"],
      orderDetails["contact_number"],
      widget.order["phone_number"],
      widget.order["phone"],
      widget.order["mobile"],
    ]) {
      if (val != null && val.toString().trim().isNotEmpty) {
        final s = val.toString().trim();
        // Strictly prevent showing the provider's own phone number
        if (providerPhone.isNotEmpty && s == providerPhone) {
          continue;
        }
        return s;
      }
    }
    return "";
  }

  String _getCustomerEmail() {
    final providerEmail = (userData["email"] ?? "").toString().trim().toLowerCase();

    if (customerProfile["email"] != null && customerProfile["email"].toString().trim().isNotEmpty) {
      final s = customerProfile["email"].toString().trim();
      if (providerEmail.isEmpty || s.toLowerCase() != providerEmail) {
        return s;
      }
    }

    for (final val in [
      customerProfile["email"],
      orderDetails["customer_email"],
      orderDetails["user_email"],
      (orderDetails["customer"] is Map ? orderDetails["customer"]["email"] : null),
      (orderDetails["user"] is Map ? orderDetails["user"]["email"] : null),
      (orderDetails["customer_details"] is Map ? orderDetails["customer_details"]["email"] : null),
      widget.order["customer_email"],
      widget.order["user_email"],
      (widget.order["customer"] is Map ? widget.order["customer"]["email"] : null),
      (widget.order["user"] is Map ? widget.order["user"]["email"] : null),
      orderDetails["email"],
      widget.order["email"],
    ]) {
      if (val != null && val.toString().trim().isNotEmpty) {
        final s = val.toString().trim();
        if (providerEmail.isNotEmpty && s.toLowerCase() == providerEmail) {
          continue;
        }
        return s;
      }
    }
    return "";
  }

  bool _isPaymentCompleted() {
    final orderStatus = (orderDetails["order_status"] ?? widget.order["order_status"] ?? widget.order["status"] ?? "").toString().toLowerCase().trim();
    if (orderStatus == "completed" || orderStatus == "2") return true;

    final status = (orderDetails["payment_status"] ?? widget.order["payment_status"] ?? "").toString().toLowerCase().trim();
    if (status == "paid" || status == "completed" || status == "success" || status == "1" || status == "true") return true;

    // Note: payment_id from booking checkout is for the GoBuddy Platform Fee,
    // not for doorstep service payment. Service payment is collected upon job completion.
    return false;
  }

  String _getPaymentMethodDisplay() {
    final isPaid = _isPaymentCompleted();
    final type = (orderDetails["payment_type"] ?? widget.order["payment_type"] ?? "").toString().toLowerCase().trim();
    if (isPaid) {
      final mode = type.isNotEmpty && type != "cash" ? type.toUpperCase() : (type == "cash" ? "CASH" : "PAID");
      return "Payment Completed ($mode)";
    }
    return "Payment Pending (Collect after service)";
  }

  /// Customer Details
  Widget _buildCustomerDetails(Size size) {
    final customerName = _getCustomerName();
    final customerPhone = _getCustomerPhone();
    final customerEmail = _getCustomerEmail();

    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Customer Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.045,
                ),
              ),
              if (customerProfile["profile"] != null && customerProfile["profile"].toString().startsWith("http"))
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    customerProfile["profile"].toString(),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
            ],
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            "Name: $customerName",
            style: TextStyle(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Phone Number: ${customerPhone.isNotEmpty ? customerPhone : 'Not provided'}",
                  style: TextStyle(fontSize: size.width * 0.033, color: Colors.grey.shade800),
                ),
              ),
              if (customerPhone.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green, size: 20.0),
                      tooltip: "Call Customer",
                      onPressed: () {
                        makePhoneCall(customerPhone);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sms_outlined, color: Colors.blue, size: 20.0),
                      tooltip: "Send SMS",
                      onPressed: () {
                        sendSMS(customerPhone, 'Hello $customerName! We are from GoBuddy regarding your service.');
                      },
                    ),
                  ],
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Email: ${customerEmail.isNotEmpty ? customerEmail : 'Not provided'}",
                  style: TextStyle(fontSize: size.width * 0.033, color: Colors.grey.shade800),
                ),
              ),
              if (customerEmail.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.email_outlined, color: Colors.deepOrange, size: 20.0),
                  tooltip: "Send Email",
                  onPressed: () {
                    sendEmail(customerEmail, 'GoBuddy Service Inquiry', 'Hello $customerName! We are from GoBuddy regarding your service.');
                  },
                ),
            ],
          ),
          if (_canPerformServiceActions()) ...[
            SizedBox(height: size.height * 0.01),
            OutlinedButton.icon(
              onPressed: () {
                _showMessageDialog(context, customerName, customerPhone);
              },
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
              label: const Text("Send message", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
            ),

            SizedBox(height: size.height * 0.01),
            if (!_isOrderAccepted())
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please accept this order first to enter customer verification code.",
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: size.width * 0.033,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!_isVerified)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter customer code",
                        prefixIcon: const Icon(Icons.pin_outlined),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      callVerifyAPI(_orderCodeController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      "Verify",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text("Order Code Verified", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showMessageDialog(BuildContext context, String customerName, String customerPhone) {
    final msgController = TextEditingController(
      text: "Hello $customerName! We are from GoBuddy regarding order #${orderDetails["order_txn"] ?? widget.order["order_txn"] ?? ""}.",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.chat_bubble_outline, color: Colors.green),
            SizedBox(width: 8),
            Text("Send Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Message to $customerName:", style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 10),
            TextField(
              controller: msgController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Type your message here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "• In-App: Sends message inside GoBuddy app to the customer.\n• SMS: Sends a text message directly to customer's mobile phone.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          if (customerPhone.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                sendSMS(customerPhone, msgController.text.trim());
              },
              icon: const Icon(Icons.sms, size: 16, color: Colors.green),
              label: const Text("Send SMS", style: TextStyle(color: Colors.green)),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final text = msgController.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              UtilClass.showProgress(context: context);
              try {
                final customerUserId = customerProfile["id"] ??
                    orderDetails["user_id"] ??
                    widget.order["user_id"] ??
                    orderDetails["customer_id"] ??
                    widget.order["customer_id"] ??
                    "";
                final orderId = orderDetails["id"] ??
                    widget.order["job_calender_id"] ??
                    widget.order["id"] ??
                    "";
                final providerId = (userData["user_id"] ?? userData["id"] ?? "").toString();

                await Repository.postApiService(EndPoints.sendMessage, {
                  "user_id": customerUserId.toString(),
                  "provider_id": providerId,
                  "order_id": orderId.toString(),
                  "message": text,
                });
                UtilClass.hideProgress();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("In-app message sent successfully!"), backgroundColor: Colors.green),
                );
              } catch (e) {
                UtilClass.hideProgress();
                if (customerPhone.isNotEmpty) {
                  sendSMS(customerPhone, text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send message: $e")),
                  );
                }
              }
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text("In-App"),
          ),
        ],
      ),
    );
  }

  /// Issue & Cancel Buttons
  Widget _buildIssueButton(Size size) {
    if (!_canPerformServiceActions()) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              _showReportIssueSheet(context);
            },
            icon: const Icon(Icons.report_problem_outlined, color: Colors.blue),
            label: const Text(
              "Report Issue",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              _showCancelDialog(context);
            },
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text(
              "Cancel Service",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showReportIssueSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Report an Issue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Order: ${orderDetails["order_txn"] ?? widget.order["order_txn"] ?? ""}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Issue Title",
                  hintText: "e.g., Customer not available, Location unreachable",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "Describe the issue in detail...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final desc = descController.text.trim();
                    if (title.isEmpty || desc.isEmpty) {
                      UtilClass.showAlertDialog(context: ctx, message: "Please fill in both title and description.");
                      return;
                    }
                    Navigator.pop(ctx);
                    UtilClass.showProgress(context: context);
                    try {
                      await Repository.postApiService("${EndPoints.newbaseUrl}support", {
                        "user_id": userData["user_id"] ?? "",
                        "title": title,
                        "description": "Order #${orderDetails["order_txn"] ?? widget.order["order_txn"] ?? ""}: $desc",
                      });
                      UtilClass.hideProgress();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Issue reported to GoBuddy Support successfully.")),
                      );
                    } catch (_) {
                      UtilClass.hideProgress();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Issue logged successfully.")),
                      );
                    }
                  },
                  child: const Text("Submit Issue", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Price Details
  Widget _buildPriceDetails(Size size, double totalAmount) {
    double sum = 0;
    for (var i = 0; i < servicesData.length; i++) {
      sum = sum + (double.tryParse(servicesData[i]["discount"]?.toString() ?? "0") ?? 0.0);
    }

    final isPaid = _isPaymentCompleted();
    final paymentText = _getPaymentMethodDisplay();

    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: isPaid ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(
                paymentText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPaid ? Colors.green : Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(),
          // Each service price
          Column(
            children: servicesData.map((service) {
              double price = _parseDouble(service["price"]);
              final q = service["quantity"] ?? service["qty"] ?? orderDetails["quantity"] ?? widget.order["quantity"] ?? 1;
              final qInt = int.tryParse(q.toString()) ?? 1;
              final qty = qInt > 0 ? qInt : 1;
              final sName = qty > 1
                  ? "${service["service_name"] ?? "Service"} (x$qty)"
                  : (service["service_name"] ?? "Service");
              final linePrice = price * qty;
              return _priceRow(sName, linePrice);
            }).toList(),
          ),

          // Display extra service charges
          if (_extraCharges.isNotEmpty)
            Column(
              children: _extraCharges.asMap().entries.map((entry) {
                final idx = entry.key;
                final charge = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        charge['description'] ?? 'Extra Service',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "₹${_parseDouble(charge['amount']).toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_canPerformServiceActions()) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  final removed = _extraCharges.removeAt(idx);
                                  _extraServiceTotal -= _parseDouble(removed['amount']);
                                  if (_extraServiceTotal < 0) _extraServiceTotal = 0.0;
                                });
                                _syncChargesToBackend();
                              },
                              child: const Icon(Icons.close, size: 16, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          _priceRow("Extra Service charge", null, isAdd: true),

          _priceRow('Discount', sum),
          if (travelingTotal > 0)
            _priceRow("Traveling Charge", travelingTotal),
          const Divider(),
          _priceRow(
            _isPaymentCompleted() || !_canPerformServiceActions()
                ? "Amount Collected"
                : "Amount to Collect",
            totalAmount,
            isBold: true,
          ),
          SizedBox(height: size.height * 0.02),
          // Only show cash/PhonePe payment collection options if order is NOT already paid
          Visibility(
            visible: !_isPaymentCompleted() && _canPerformServiceActions(),
            child: Container(
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Collect Payment from Customer via",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _paymentOption(0, "Payment via PhonePe (UPI)"),
                  _paymentOption(1, "By hand cash"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String title,
    double? amount, {
    bool isBold = false,
    bool isAdd = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          GestureDetector(
            onTap: isAdd
                ? () {
                    _showAddServiceChargeDialog();
                  }
                : null,
            child: Text(
              isAdd
                  ? "ADD"
                  : amount != null
                  ? (title.toLowerCase().contains("discount") && amount > 0
                      ? "-₹${amount.toStringAsFixed(2)}"
                      : "₹${amount.toStringAsFixed(2)}")
                  : "",
              style: TextStyle(
                color: isAdd
                    ? Colors.green
                    : (title.toLowerCase().contains("discount") && amount != null && amount > 0
                        ? Colors.green
                        : Colors.black),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Popup for Adding Extra Service Charge - FIXED VERSION
  void _showAddServiceChargeDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Add Extra Service Charge",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// Enter Amount
                            TextFormField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Enter Amount",
                                prefixIcon: const Icon(Icons.currency_rupee),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),

                            /// Add Description
                            TextFormField(
                              controller: descController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Add Description",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            double amount = double.parse(amountController.text);
                            String description = descController.text;

                            // Add the extra charge
                            setState(() {
                              _extraCharges.add({
                                'amount': amount,
                                'description': description,
                              });
                              _extraServiceTotal += amount;
                            });
                            _syncChargesToBackend();

                            print(
                              "Extra Charge Added: ₹$amount, Desc: $description",
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          "Add",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _paymentOption(int index, String title) {
    return RadioListTile<int>(
      title: Text(title),
      value: index,
      groupValue: _selectedPaymentIndex,
      onChanged: (val) {
        setState(() {
          _selectedPaymentIndex = val!;
        });
      },
    );
  }

  /// Submit Button
  Widget _buildSubmitButton(Size size) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // Remove backgroundColor and use foregroundColor for text color
          foregroundColor: Colors.white,
          // Set transparent background to allow the gradient to show
          backgroundColor: Colors.transparent,
          // Remove shadow
          elevation: 0,
        ),
        onPressed: () {
          // ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text("Details Submitted")));
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFd4c900), Color(0xFF00ad20)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: BoxConstraints(
              minWidth: double.infinity,
              minHeight: size.height * 0.035 * 2, // Match button padding
            ),
            child: const Text(
              "Submit Details",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16, // Optional: adjust font size if needed
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///services
  Widget _buildServiceTabs(Size size) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: servicesData.length,
        separatorBuilder: (_, __) => SizedBox(width: 10),
        itemBuilder: (context, index) {
          bool isSelected = selectedServiceIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedServiceIndex = index;
                serviceData = servicesData[index];
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                servicesData[index]["service_name"],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- SELECTED SERVICE CARD ----------------
  Widget _buildSelectedServiceCard(Size size) {
    final service = servicesData[selectedServiceIndex];

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 5,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              UtilClass.formatImageUrl(service["service_image"]?.toString()),
              errorBuilder: (context, error, stackTrace) {
                // Returns this widget if the image fails to load
                return const Icon(Icons.broken_image, size: 50);
              },
              width: size.width * 0.22,
              height: size.width * 0.22,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service["service_name"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.043,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Text(
                    "Quantity: ${service["quantity"] ?? service["qty"] ?? orderDetails["quantity"] ?? widget.order["quantity"] ?? 1}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                SizedBox(height: 6),

                Text(
                  "location",
                  maxLines: 2,
                  style: TextStyle(fontSize: size.width * 0.035),
                ),

                SizedBox(height: 8),

                Text(
                  "₹${service['price']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.045,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadImageTitle(Size size) {
    return Text(
      "Upload Service Images",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: size.width * 0.045,
      ),
    );
  }

  // ---------------- UPLOAD BOXES ----------------
  Widget _imageUploadSection(Size size) {
    final currentService = servicesData[selectedServiceIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Before Service", style: TextStyle(fontSize: size.width * 0.04)),
        SizedBox(height: 8),

        _serviceImageGrid(currentService["beforeImages"], true),

        SizedBox(height: 15),

        Text("After Service", style: TextStyle(fontSize: size.width * 0.04)),
        SizedBox(height: 8),

        _serviceImageGrid(currentService["afterImages"], false),
      ],
    );
  }

  Widget _serviceImageGrid(List images, bool isBefore) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var img in images)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: FileImage(img), fit: BoxFit.cover),
            ),
          ),

        GestureDetector(
          onTap: () => pickServiceImage(isBefore),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Icon(Icons.add, size: 35, color: Colors.green),
          ),
        ),
      ],
    );
  }

  // ---------------- ACTION BUTTONS ----------------
  Widget _buildActionButtons(Size size) {
    return Visibility(
      visible: orderDetails["order_status"] == "Scheduled",
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showCancelDialog(context);
              },
              child: const Text(
                "Cancel Service",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Expanded(
          //   child: ElevatedButton(
          //     style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          //     onPressed: () {},
          //     child: const Text("Service Completed"),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _showCancelReasonSheet(
    BuildContext context,
    GetCancelOrderReasons? getCancelReasons,
  ) {
    if (getCancelReasons == null || getCancelReasons.cancelReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cancel reasons not available")),
      );
      return;
    }

    int? _selectedReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: width * 0.06,
                right: width * 0.06,
                top: height * 0.02,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  Text(
                    "Select the reason",
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: height * 0.015),

                  ...getCancelReasons.cancelReasons.map((reason) {
                    final isSelected = _selectedReason == int.tryParse(reason.id);
                    return InkWell(
                      onTap: () {
                        setSheetState(() {
                          _selectedReason = int.tryParse(reason.id);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                reason.reason,
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected ? Colors.orange : Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: height * 0.025),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedReason == null
                            ? Colors.grey.shade300
                            : Colors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _selectedReason == null
                          ? null
                          : () {
                              Navigator.pop(context);

                              final selectedReasonObj = getCancelReasons.cancelReasons.firstWhere(
                                (r) => int.tryParse(r.id) == _selectedReason,
                                orElse: () => getCancelReasons.cancelReasons.first,
                              );

                              _ConfirmCancellation(
                                _selectedReason!,
                                selectedReasonObj.reason,
                                widget.order["id"]?.toString() ?? "",
                              );
                            },
                      child: Text(
                        "Cancel Service",
                        style: TextStyle(
                          color: _selectedReason == null
                              ? Colors.grey.shade600
                              : Colors.white,
                          fontSize: width * 0.042,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.03),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomCancelReasonPopup(
    BuildContext context,
    int selectedReasonId,
  ) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Please write reason",
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: height * 0.02),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Write here",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.03),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = reasonController.text.trim();

                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter a reason"),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      _ConfirmCancellation(selectedReasonId, text, "");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text("Cancel"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ConfirmCancellation(
    int reasonId,
    String reasonText,
    String jobCalendarId,
  ) async {
    try {
      debugPrint("📌 Cancel API Called:");
      debugPrint("Reason ID: $reasonId");
      debugPrint("Reason: $reasonText");
      debugPrint("Job Calendar ID: $jobCalendarId");

      callCancelAPI(reasonText);

      //_showCancelRequestPopup(context);

      // TODO: Replace with real API
      // await Future.delayed(const Duration(seconds: 1));
      // _showCancelRequestPopup(context);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Order Cancelled Successfully")),
      // );
    } catch (e) {
      debugPrint("Cancel API Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to cancel order")));
    }
  }
  //cancel order

  //services end
}
