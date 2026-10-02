import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/boras_touch_models/getupdateaddress_model.dart';
import 'package:gobuddy/models/dash_earnings_model.dart';
import 'package:gobuddy/models/dashboard_subscription_model.dart';
import 'package:gobuddy/models/dashmodel.dart';
import 'package:gobuddy/models/getalert.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../utils/config.dart';
import '../../utils/my_colors.dart';
import '../orders/my_orders.dart';

class DashboardTabScreen extends StatefulWidget {
  const DashboardTabScreen({super.key});

  static void markOrderHandled(String? id) => _DashboardTabScreenState.markOrderHandled(id);

  @override
  State<DashboardTabScreen> createState() => _DashboardTabScreenState();
}

class _DashboardTabScreenState extends State<DashboardTabScreen> {
  int currentIndex = 0;
  dynamic profileDetails = {};
  dynamic dashBoardDetails = {};
  Color green = Color(0xFF4CAF50);
  dynamic userData = {};
  String? ProviderId;
  GetMyLiveAlert? pushintoLiveAlert;
  Orders? getmyOders;
    bool _isAlertShowing = false;
   Timer? _userCheckTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _lastOrderId;
  static final Set<String> handledOrderIds = <String>{};
  static void markOrderHandled(String? id) {
    if (id != null && id.trim().isNotEmpty) handledOrderIds.add(id.trim());
  }
  GetDashboardDetails?pushintoDashboardDetails;
  Profile?getmyProfile;
  GetDashboardDetailsModel?pushintoDashEarningsModel;
  Summary?mysummary;
GetMySubscriptionModel? pushintosubscriptionModel;
List<Data> getDashboardSubscriptionData = [];
GetUpdateAddressModel? pushintoUpdateAddressModel;

  // ── Live location / address-update state ────────────────────────────────────
  String _currentAddress = "";
  bool _isFetchingLocation = false;
  bool _isUpdatingAddress = false;
  double? _currentLat;
  double? _currentLng;
  final TextEditingController _manualAddressController = TextEditingController();








  
  
  //sk
  // Assume the data is flattened for easier calculation
  late List<Map<String, dynamic>> _allEarningsData;
  late int
  _currentIndex;

  static const Color orange = Color(0xFFFF8C00);
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;




  static const Color lightBlue = Color(
    0xFFBBDEFB,
  ); 
  static const Color textOrange = Color(
    0xFFFF913C,
  ); // Orange for '20% OFF' and fire icon
  Map<String, dynamic> dashboardData = {
    "isVerified": false, 
    "rating": 3.0,
    "location": "35/08-PM Palem, Madhurawada, Visakhapatnam...",
    "profileImageUrl": 'assets/images/user.jpg',
    "totalEarnings": "0",
    "jobsGoal": "0 Orders",
    "statusCards": [],

    "statistics": {
      "currentMonth": "Jan",
      "currentYear": DateTime.now().year,
      "earnings": [
        {"month": "Jan", "year": DateTime.now().year, "earning": 0},
        {"month": "Feb", "year": DateTime.now().year, "earning": 0},
        {"month": "Mar", "year": DateTime.now().year, "earning": 0},
        {"month": "Apr", "year": DateTime.now().year, "earning": 0},
        {"month": "May", "year": DateTime.now().year, "earning": 0},
        {"month": "Jun", "year": DateTime.now().year, "earning": 0},
        {"month": "Jul", "year": DateTime.now().year, "earning": 0},
        {"month": "Aug", "year": DateTime.now().year, "earning": 0},
        {"month": "Sep", "year": DateTime.now().year, "earning": 0},
        {"month": "Oct", "year": DateTime.now().year, "earning": 0},
        {"month": "Nov", "year": DateTime.now().year, "earning": 0},
        {"month": "Dec", "year": DateTime.now().year, "earning": 0},
      ],
    },

    "offers": [
      
    ],
  };

@override
void initState() {
  super.initState();

  var userDataValue = Preferences.getUserDetails();
  if (userDataValue != null) {
    userData = json.decode(userDataValue);
  }

  getAllServices();
  _getMyProfileDetails();
    _startUserCheckTimer();
    _getMyEarningsIncome();
    _getDashboardSubscriptions();
    _getProviderRating();

  final now = DateTime.now();
  final monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  dashboardData["statistics"]["currentMonth"] = monthNames[now.month - 1];

  _allEarningsData = dashboardData["statistics"]["earnings"]
      .cast<Map<String, dynamic>>();

  String initialMonth = dashboardData["statistics"]["currentMonth"];
  _currentIndex = _allEarningsData.indexWhere(
    (data) => data["month"] == initialMonth,
  );

  if (_currentIndex == -1) {
    _currentIndex = _allEarningsData.isNotEmpty
        ? _allEarningsData.length - 1
        : 0;
  }

  _currentPage = 0;
  _startAutoScroll();

  _pageController.addListener(() {
    final next = _pageController.page?.round();
    if (next != null && _currentPage != next) {
      setState(() {
        _currentPage = next;
      });
    }
  });

  // /// ✅ Start periodic task AFTER widget is built
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  //   _startUserCheckTimer();
  // });
}





  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _userCheckTimer?.cancel();
    _audioPlayer.dispose();
    _manualAddressController.dispose();
 
    super.dispose();
  }

  
  bool _isCheckingAlert = false;

  void _startUserCheckTimer() {
    _userCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_isCheckingAlert) return;
        _isCheckingAlert = true;
        try {
          await _getMyOrderAlert();
        } finally {
          _isCheckingAlert = false;
        }
      },
    );
  }

  void _showVerificationPendingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.hourglass_top, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Verification Under Review",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          "Your profile and KYC documents are currently pending admin verification. You will be able to create packages and purchase subscriptions once your account is verified.",
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, Config.myDocumentsRouteName);
            },
            child: const Text("View My Documents"),
          ),
        ],
      ),
    );
  }

  /// Returns false and shows an alert if there is no internet.
  Future<bool> _checkNet() async {
    final ok = await UtilClass.checkInternet();
    if (!ok && mounted) {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
    return ok;
  }

  // ── Fetch device GPS location, reverse-geocode it, then push it live to the server ──
  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          UtilClass.showAlertDialog(
            context: context,
            message:
                "Location permission permanently denied. Enable it in settings.",
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "";
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address =
            "${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''} ${p.postalCode ?? ''}";
        address = address.trim();
      }

      if (mounted) {
        setState(() {
          _currentAddress = address;
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
      }

      // Tapping "Use Current Location" IS the confirmation for this flow,
      // so immediately push the live address + lat/lng to the server.
      if (address.isNotEmpty) {
        await _updateAddressOnServer(
          address,
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (e) {
      debugPrint("Location error: $e");
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Could not fetch location: $e",
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ── Bottom sheet: "Use Current Location" or type an address manually ────────
  void _showAddressBottomSheet() {
    _manualAddressController.text =
        _currentAddress.isNotEmpty ? _currentAddress : (getmyProfile?.address ?? "");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // StatefulBuilder lets the sheet show its own local "confirming..." spinner
        // without needing to rebuild the whole dashboard.
        bool isConfirming = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Set Your Location",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Use current location button
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _fetchCurrentLocation();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: MyColors.appThemeLight),
                        borderRadius: BorderRadius.circular(10),
                        color: MyColors.appThemeLight.withOpacity(0.07),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.my_location,
                              color: MyColors.appThemeLight, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Use Current Location",
                                  style: TextStyle(
                                    color: MyColors.appThemeLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_isFetchingLocation)
                                  const Text("Fetching...",
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey))
                                else
                                  const Text("Uses GPS to detect your location",
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          if (_isFetchingLocation)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(Icons.chevron_right,
                                color: MyColors.appThemeLight),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Or enter manually",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  // Manual text field
                  TextField(
                    controller: _manualAddressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "e.g. 44-45-34, Venkateswara Colony, Hyderabad",
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: MyColors.appThemeLight, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColors.appThemeLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isConfirming
                          ? null
                          : () async {
                              final entered =
                                  _manualAddressController.text.trim();
                              if (entered.isEmpty) {
                                Navigator.pop(ctx);
                                return;
                              }

                              setSheetState(() => isConfirming = true);

                              // Geocode the typed address so we still capture
                              // live lat/lng for the API params.
                              double? lat;
                              double? lng;
                              try {
                                final locations =
                                    await locationFromAddress(entered);
                                if (locations.isNotEmpty) {
                                  lat = locations.first.latitude;
                                  lng = locations.first.longitude;
                                  debugPrint(
                                      "📍 Geocoded '$entered' → lat=$lat, lng=$lng");
                                } else {
                                  debugPrint(
                                      "⚠️ Geocoding returned an empty list for '$entered'");
                                }
                              } catch (e) {
                                debugPrint(
                                    "❌ Geocoding manual address failed: $e");
                              }

                              Navigator.pop(ctx);

                              await _updateAddressOnServer(
                                entered,
                                lat: lat,
                                lng: lng,
                              );
                            },
                      child: isConfirming
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Confirm Location",
                              style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



Future<void> _updateAddressOnServer(
  String newAddress, {
  double? lat,
  double? lng,
}) async {
  if (!await _checkNet()) return;
  final uid = userData?['user_id'];
  if (uid == null) {
    debugPrint("❌ _updateAddressOnServer aborted: userData['user_id'] is null");
    return;
  }

  if (mounted) setState(() => _isUpdatingAddress = true);
 final params = {
  "user_id": uid ?? "",
  "address": newAddress,
  "latitude": lat?.toString() ?? "",  
  "longitude": lng?.toString() ?? "",
  "place_id": "",
  "landmark": newAddress,
  "location": ""
};

  debugPrint("📤 updateAddress REQUEST → endpoint: ${EndPoints.getUpdateAddress}");
  debugPrint("📤 updateAddress PARAMS  → $params");

  try {
    final response = await Repository.postApiService(
      EndPoints.getUpdateAddress,
      params,
    );

    Map<String, dynamic> jsonResponse;
    if (response is String) {
      jsonResponse = json.decode(response) as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      jsonResponse = response;
    } else {
      debugPrint("❌ updateAddress FAILED → unexpected response type: ${response.runtimeType}");
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Unexpected server response. Please try again.",
        );
      }
      return;
    }

    debugPrint("📥 updateAddress PARSED  → $jsonResponse");
    debugPrint("📥 updateAddress status='${jsonResponse['status']}' message='${jsonResponse['message']}'");

    if (jsonResponse['status'] == 'valid' || jsonResponse['status'] == 'success' || jsonResponse['status'] == true) {
      if (mounted) {
        setState(() {
          pushintoUpdateAddressModel = GetUpdateAddressModel.fromJson(jsonResponse);
          // `Profile.address` is a final field on the generated model, so it
          // can't be reassigned here. Instead, _currentAddress takes priority
          // in the UI (see the location Row in build()), so this alone is
          // enough to reflect the freshly-confirmed address everywhere it's shown.
          _currentAddress = newAddress;
          if (lat != null) _currentLat = lat;
          if (lng != null) _currentLng = lng;
        });
      }

      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse['message'] ?? "Address updated successfully.",
        );
      }
    } else {
      final reason = jsonResponse['message'] ??
          jsonResponse['error'] ??
          "status='${jsonResponse['status']}' (no message field returned)";
      debugPrint("❌ updateAddress REJECTED by server → $reason");

      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Update failed: $reason",
        );
      }
    }
  } catch (e, stackTrace) {
    debugPrint("❌ updateAddress EXCEPTION → $e");
    debugPrint("❌ updateAddress STACKTRACE → $stackTrace");
    if (mounted) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Failed to update address: $e",
      );
    }
  } finally {
    if (mounted) setState(() => _isUpdatingAddress = false);
  }
}
 
 


Future<void> _getDashboardSubscriptions()async {
  bool internet  = await UtilClass.checkInternet();
  if(!internet){
    UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
    return;
  }

  try {
    final response = await Repository.postApiService(EndPoints.getMySUbscriptonDashboard, {
      'provider_id' : userData['user_id']?? ""
    });

    Map<String, dynamic>jsonResponse;
    if(response is String){
      jsonResponse =  json.decode(response);
    }else{
      jsonResponse = response;
    }

    if(jsonResponse['status']=='valid'){
      pushintosubscriptionModel = GetMySubscriptionModel.fromJson(jsonResponse);
      setState(() {
        getDashboardSubscriptionData = pushintosubscriptionModel?.data??[];
      });
    }
  } catch (e) {
   print("Something went wrong while fetching subscriptions: $e");
  }
}

Future<void> _getMyEarningsIncome()async {
  bool internet  = await UtilClass.checkInternet();
  if(!internet){
    UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
    return;
  }

  try {
    
  final response = await Repository.postApiService(EndPoints.getmyEarnings, {
    'provider_id' : userData['user_id'] ?? ""
  });

  Map<String, dynamic>jsonResponse;
  if(response is String){
    jsonResponse = json.decode(response);
  }else{
    jsonResponse = response;
  }


  if(jsonResponse['status']=='valid'){
    pushintoDashEarningsModel = GetDashboardDetailsModel.fromJson(jsonResponse);
    setState(() {
      mysummary = pushintoDashEarningsModel?.summary;
      if (mysummary != null) {
        dashboardData["totalEarnings"] = mysummary?.monthTotal ?? "0";
        dashboardData["jobsGoal"] = "${mysummary?.monthCount ?? 0} Orders";
        final yearlyStats = pushintoDashEarningsModel?.yearlyStatistics;
        if (yearlyStats != null && yearlyStats.months.isNotEmpty) {
          for (var m in yearlyStats.months) {
            final mShort = m.monthShort ?? "";
            final yr = int.tryParse(m.year ?? "") ?? DateTime.now().year;
            final amt = double.tryParse(m.amount?.replaceAll(',', '') ?? '0') ?? 0;
            final idx = _allEarningsData.indexWhere((e) => e["month"] == mShort);
            if (idx != -1) {
              _allEarningsData[idx]["earning"] = amt;
              _allEarningsData[idx]["year"] = yr;
            }
          }
        } else {
          try {
            final now = DateTime.now();
            final monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            final currentMonthName = monthNames[now.month - 1];
            final currentMonthVal = double.tryParse(mysummary?.monthTotal?.replaceAll(',', '') ?? '0') ?? 0;
            final idx = _allEarningsData.indexWhere((e) => e["month"] == currentMonthName && e["year"] == now.year);
            if (idx != -1) {
              _allEarningsData[idx]["earning"] = currentMonthVal;
            }
          } catch (_) {}
        }
        dashboardData["statusCards"] = [
          {
            "title": "Current Month",
            "amount": mysummary?.monthTotal ?? "0",
            "count": mysummary?.monthCount ?? 0,
            "color": 0xFF4A90E2,
          },
          {
            "title": "Today Orders",
            "amount": mysummary?.todayTotal ?? "0",
            "count": mysummary?.todayCount ?? 0,
            "color": 0xFF2ECC71,
          },
          {
            "title": "Pending Orders",
            "amount": mysummary?.pendingTotal ?? "0",
            "count": mysummary?.pendingCount ?? 0,
            "color": 0xFFF39C12,
          },
          {
            "title": "Missed Orders",
            "amount": mysummary?.missedTotal ?? "0",
            "count": mysummary?.missedCount ?? 0,
            "color": 0xFFE74C3C,
          },
        ];
      }
    });
  }
    
  } catch (e) {
    print("Something went wrong while fetching earnings: $e");
  }
}

Future<void> _getProviderRating() async {
  try {
    final pId = userData?['user_id'];
    if (pId == null) return;
    final response = await Repository.postApiService(
      EndPoints.providerRatingsReviews,
      {"provider_id": pId},
    );
    final dynamic parsed =
        response is String ? json.decode(response) : response;
    if (parsed is Map<String, dynamic> &&
        (parsed["status"] == "valid" || parsed["status"] == true)) {
      final dynamic overall =
          parsed["overall_rating"] ?? parsed["rating"] ?? parsed["average_rating"];
      if (overall != null && mounted) {
        setState(() {
          dashboardData["rating"] =
              double.tryParse(overall.toString()) ?? dashboardData["rating"];
        });
      }
    }
  } catch (e) {
    debugPrint("Error fetching provider rating: $e");
  }
}


Future<void> _getMyProfileDetails() async {
  bool internet = await UtilClass.checkInternet();
  if (!internet) {
    UtilClass.showAlertDialog(
      context: context,
      message: "No Internet Connection",
    );
    return;
  }

  try {
    final response = await Repository.postApiService(
      EndPoints.getProfileDetails,
      {
        'user_id': userData?['user_id'],
      },
    );

    late GetDashboardDetails dashboardDetails;

    if (response is String) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response);
      dashboardDetails = GetDashboardDetails.fromJson(jsonResponse);
    } else if (response is Map<String, dynamic>) {
      dashboardDetails = GetDashboardDetails.fromJson(response);
    } else {
      throw Exception("Invalid response type");
    }

    final p = dashboardDetails.profile;
    Map<String, dynamic> profMap = {};
    if (p != null) {
      profMap = p.toJson();
    }
    final bool isApproved = UtilClass.isProviderVerified(profMap);

    setState(() {
      pushintoDashboardDetails = dashboardDetails;
      getmyProfile = p;
      dashboardData["isVerified"] = isApproved;
    });

    try {
      final userMap = Map<String, dynamic>.from(userData ?? {});
      userMap['isVerified'] = isApproved;
      if (p?.adminApprovalProvider != null) userMap['admin_approval_provider'] = p!.adminApprovalProvider;
      if (p?.ekycStatus != null) userMap['ekyc_status'] = p!.ekycStatus;
      if (p?.ekycStatusName != null) userMap['ekyc_status_name'] = p!.ekycStatusName;
      Preferences.setUserDetails(json.encode(userMap));
      userData = userMap;
    } catch (_) {}
  } catch (e) {
    debugPrint("Error fetching profile details: $e");
    print("Error fetching profile details: $e");
  }
}




Future<void> _getMyOrderAlert() async {
  try {
    
    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      debugPrint(' No internet connection');
      return;
    }

    final response = await Repository.postApiService(
      EndPoints.getOderAlert,
      {
        'user_id': userData?['user_id'],
      },
    );

    Map<String, dynamic> jsonResponse;

    if (response is String) {
      jsonResponse = jsonDecode(response);
    } else if (response is Map<String, dynamic>) {
      jsonResponse = response;
    } else {
      debugPrint(' Invalid response type');
      return;
    }

    final alert = GetMyLiveAlert.fromJson(jsonResponse);
    if (alert.status != 'success') {
      debugPrint(' API status: ${alert.status}');
      return;
    }

    if (alert.orders.isEmpty) {
      debugPrint(' No new orders');
      return;
    }

    final Orders newOrder = alert.orders.first;

    final String ordId = newOrder.orderId?.toString().trim() ?? "";
    final String calId = newOrder.jobCalendarId?.toString().trim() ?? "";

    if ((ordId.isNotEmpty && handledOrderIds.contains(ordId)) ||
        (calId.isNotEmpty && handledOrderIds.contains(calId))) {
      return;
    }

    if (ordId.isNotEmpty && _lastOrderId == ordId) return;
    if (_isAlertShowing) return;

    if (ordId.isNotEmpty) {
      _lastOrderId = ordId;
      handledOrderIds.add(ordId);
    }
    if (calId.isNotEmpty) handledOrderIds.add(calId);

    if (!mounted) return;

    debugPrint(' Showing order alert: ${newOrder.orderId}');
    _showOrderAlert(newOrder);

  } on FormatException catch (e) {
    debugPrint(' JSON format error: ${e.message}');
  } catch (e, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
  }
}
  void _showOrderAlert(Orders order) {
    _isAlertShowing = true;
    _playRingtone();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final imgUrl = (order.serviceImage != null && order.serviceImage!.isNotEmpty)
            ? "https://dev.gobuddyindia.com/assets/images/${order.serviceImage}"
            : "";

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Color(0xFFF57C00),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "New Order Alert",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      "₹ ${order.price ?? '0'}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Service details row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 70,
                      width: 70,
                      color: Colors.grey.shade100,
                      child: imgUrl.isNotEmpty
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.handyman,
                                size: 36,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.handyman,
                              size: 36,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.serviceName ?? "Customer Service Request",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (order.note != null && order.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            order.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 6),
                              Text(
                                "${order.scheduleDate ?? ''} ${order.scheduleTime ?? ''}".trim().isEmpty
                                    ? "Immediate / Scheduled"
                                    : "${order.scheduleDate ?? ''} ${order.scheduleTime ?? ''}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final ordId = order.orderId?.toString().trim() ?? "";
                          final calId = order.jobCalendarId?.toString().trim() ?? "";
                          if (ordId.isNotEmpty) handledOrderIds.add(ordId);
                          if (calId.isNotEmpty) handledOrderIds.add(calId);
                          _stopRingtone();
                          _isAlertShowing = false;
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Decline",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          "Accept Order",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () {
                          final ordId = order.orderId?.toString().trim() ?? "";
                          final calId = order.jobCalendarId?.toString().trim() ?? "";
                          if (ordId.isNotEmpty) handledOrderIds.add(ordId);
                          if (calId.isNotEmpty) handledOrderIds.add(calId);
                          _stopRingtone();
                          _isAlertShowing = false;
                          Navigator.pop(context);
                          _acceptOrder(order);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _stopRingtone();
      _isAlertShowing = false;
    });
  }

  void _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource('sounds/ring.mp3'));
    } catch (_) {}
  }

  void _stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _acceptOrder(Orders order) async {
    final calId = (order.jobCalendarId != null && order.jobCalendarId!.isNotEmpty)
        ? order.jobCalendarId
        : order.orderId;
    if (calId == null || calId.isEmpty) {
      UtilClass.showAlertDialog(context: context, message: "Order identifier missing");
      return;
    }

    final providerId = userData?["user_id"]?.toString() ?? "";
    if (providerId.isEmpty) {
      UtilClass.showAlertDialog(context: context, message: "Provider session invalid");
      return;
    }

    UtilClass.showProgress(context: context);
    try {
      final response = await Repository.postApiService(
        EndPoints.orderaccept,
        {
          "job_calender_id": calId,
          "provider_id": providerId,
        },
      );

      UtilClass.hideProgress();

      dynamic parsed = response;
      if (response is String) {
        try {
          parsed = json.decode(response);
        } catch (_) {}
      }

      if (parsed != null && (parsed["status"] == "valid" || parsed["status"] == true || parsed["status"] == "success")) {
        final ordId = order.orderId?.toString().trim() ?? "";
        final calId = order.jobCalendarId?.toString().trim() ?? "";
        if (ordId.isNotEmpty) handledOrderIds.add(ordId);
        if (calId.isNotEmpty) handledOrderIds.add(calId);
        _lastOrderId = ordId.isNotEmpty ? ordId : calId;
        _stopRingtone();
        _isAlertShowing = false;

        UtilClass.showAlertDialog(
          context: context,
          message: parsed["message"] ?? "Order accepted successfully!",
        );
        _getMyEarningsIncome();
        _getDashboardSubscriptions();

        // Navigate provider to My Orders screen
        Navigator.pushNamed(context, Config.myOrdersRouteName);
      } else {
        UtilClass.showAlertDialog(
          context: context,
          message: parsed?["message"] ?? "Unable to accept order. It may have already been assigned.",
        );
      }
    } catch (e) {
      UtilClass.hideProgress();
      UtilClass.showAlertDialog(
        context: context,
        message: "Failed to accept order. Please check your network.",
      );
    }
  }

  void _startAutoScroll() {
    final offers = dashboardData["offers"] as List<dynamic>;
    if (offers.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % offers.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _changeMonth(int direction) {
    setState(() {
      int newIndex = _currentIndex + direction;
      if (newIndex >= 0 && newIndex < _allEarningsData.length) {
        _currentIndex = newIndex;
      }
    });
  }

  List<Map<String, dynamic>> _getVisibleData() {
    int centerIndex = _currentIndex;
    int startIndex = max(0, centerIndex - 2);
    int endIndex = min(_allEarningsData.length, startIndex + 5);

    // Adjust start index if we hit the end bound
    if (endIndex - startIndex < 5) {
      startIndex = max(0, endIndex - 5);
    }

    return _allEarningsData.sublist(startIndex, endIndex);
  }

  void getAllServices() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      try {
        UtilClass.showProgress(context: context);
        List<dynamic> results = await Future.wait([
          Repository.postApiService(EndPoints.profile, {
            "user_id": userData["user_id"] ?? "",
          }),
          Repository.postApiService(EndPoints.dashboard, {
            "provider_id": userData["user_id"] ?? "",
          }),
           Repository.postApiService(EndPoints.advertise, {
            "provider_id": userData["user_id"] ?? "",
          }),
        ]);
        UtilClass.hideProgress();


        ////Profile//
        ///
        /// UtilClass.hideProgress();
        dynamic parsed = {};

        try {
          parsed = await json.decode(results[0]);
          if (parsed["status"] == "valid") {
            profileDetails = parsed["profile"];

            setState(() {
              profileDetails = parsed["profile"];
              ProviderId = userData['user_id'];
            });
          } 
        } catch (e) {
          print(e);
        }

        ///
        ///
        dynamic dparsed = {};
        try {
          dparsed = await json.decode(results[1]);
          if (dparsed["status"] == "valid") {
            dashBoardDetails = dparsed["summary"];

            dynamic dashboardcards = [
              {
                "title": "Current Month",
                "amount": (dashBoardDetails["month_total"] ?? mysummary?.monthTotal ?? "0").toString(),
                "count": dashBoardDetails["month_count"] ?? 0,
                "color": 0xFFFF7DA7,
                "icon": "calendar_today",
              },
              {
                "title": "Pending Orders",
                "amount": (dashBoardDetails["pending_total"] ?? mysummary?.pendingTotal ?? "0").toString(),
                "count": dashBoardDetails["pending_count"] ?? 0,
                "color": 0xFF62D5F8,
                "icon": "assignment_outlined",
              },
              {
                "title": "Today Orders",
                "amount": (dashBoardDetails["today_total"] ?? mysummary?.todayTotal ?? "0").toString(),
                "count": dashBoardDetails["today_count"] ?? 0,
                "color": 0xFF58C75E,
                "icon": "today_outlined",
              },
              {
                "title": "Missed Orders",
                "amount": (dashBoardDetails["missed_total"] ?? mysummary?.missedTotal ?? "0").toString(),
                "count": dashBoardDetails["missed_count"] ?? 0,
                "color": 0xFFFF913C,
                "icon": "inventory_outlined",
              },
            ];

            dashboardData["statusCards"] = dashboardcards;
            dashboardData["totalEarnings"] =
                dashBoardDetails["completed_total"];
            dashboardData["gbCoins"] = dashBoardDetails["gbcoins"];
            dashboardData["jobsGoal"] = dashBoardDetails["completed_count"];

            setState(() {
              dashboardData = dashboardData;
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

        //

 dynamic dashparsed = {};
        try {
          dashparsed = await json.decode(results[2]);
          if (dashparsed["status"] == "valid") {
            
              dashboardData["offers"] =  dashparsed["advertisements"];
             setState(() {
              dashboardData = dashboardData;
            });
          } else {
            // ignore: use_build_context_synchronously
            UtilClass.showAlertDialog(
              // ignore: use_build_context_synchronously
              context: context,
              message: dashparsed["message"],
            );
          }
        } catch (e) {
          print(e);
        }
        print('All data fetched:');
      } catch (e) {
        UtilClass.hideProgress();
        print('An error occurred: $e');
      }
    } else {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void callgetProfileAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.profile, {
        "user_id": userData["user_id"] ?? "",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            profileDetails = parsed["profile"];

            setState(() {
              profileDetails = parsed["profile"];
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
        print(parsed["message"]);
      });
    } else {
      // ignore: use_build_context_synchronously
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerified = dashboardData["isVerified"] as bool;

    // The logic is now passed the selected month/year data
    final selectedMonthData = _allEarningsData[_currentIndex];
    final selectedMonthName = selectedMonthData["month"];
    final selectedYear = selectedMonthData["year"];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Container with Gradient and Profile Info
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: screenHeight * 0.02,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF38B03F), const Color(0xFFC7BB47)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(
                            builder: (context) {
                              final String ekycStat = (getmyProfile?.ekycStatus ?? "").toString().trim().toLowerCase();
                              final String ekycName = (getmyProfile?.ekycStatusName ?? "").toString().trim().toLowerCase();
                              final String adminStat = (getmyProfile?.adminApprovalProvider ?? "").toString().trim().toLowerCase();
                              final bool isRejected = ekycStat == "rejected" || ekycName == "rejected" || adminStat == "rejected";

                              Color dotColor;
                              String labelText;
                              Color textColor;

                              if (isVerified) {
                                dotColor = const Color(0xFF00E676);
                                labelText = "Approved";
                                textColor = Colors.white;
                              } else if (isRejected) {
                                dotColor = Colors.redAccent;
                                labelText = "Rejected";
                                textColor = Colors.red.shade200;
                              } else {
                                dotColor = Colors.orange;
                                labelText = "Under Review";
                                textColor = Colors.yellow;
                              }

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: screenWidth * 0.035,
                                    height: screenWidth * 0.035,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    labelText,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    //add pending status
                    // Profile Row with Notification Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
  radius: screenWidth * 0.075,
  backgroundColor: Colors.grey[200], // fallback background color
  child: ClipOval(
    child: getmyProfile?.profile != null && getmyProfile!.profile!.isNotEmpty
        ? Image.network(
            getmyProfile?.profile??"",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Show broken icon if image fails to load
              return Icon(
                Icons.broken_image,
                size: screenWidth * 0.075,
                color: Colors.grey,
              );
            },
          )
        : Icon(
            Icons.person, // default icon if no profile image
            size: screenWidth * 0.075,
            color: Colors.grey,
          ),
  ),
),

                                // Green Tick for Verified Provider (Below Profile Image)
                                if (isVerified)
                                  Positioned(
                                    bottom: -2,
                                    left: 0,
                                    right: -21,
                                    child: Center(
                                      child: Container(
                                        // decoration: BoxDecoration(
                                        //   color: Colors.white,
                                        //   shape: BoxShape.circle,
                                        // ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: green,
                                          size: screenWidth * 0.05,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getmyProfile?.name??"",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.048,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                             Text(
  getmyProfile?.skills ?? "",
  maxLines: 2,             
  softWrap: false,
  overflow: TextOverflow.ellipsis, 
  style: TextStyle(
    color: Colors.white70,
    fontSize: screenWidth * 0.020,
  ),
)

,
                                // Provider Rating (Only if Verified)
                                if (isVerified)
                                  Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (index) => Icon(
                                          index <
                                                  (dashboardData["rating"] ?? 0)
                                                      .toInt()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.yellow,
                                          size: screenWidth * 0.035,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "${dashboardData["rating"] ?? 0}/5",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.035,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        // Notification Icon and PENDING Tag
                        Row(
                          children: [
                            // Notification Icon
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    arguments: {
                                      'provider_id' : userData['user_id']
                                    },
                                     Config.getNotificationsScreen);
                                },
                                icon: Icon(
                                  Icons.notifications,
                                  color: green,
                                  size: screenWidth * 0.09,
                                ),
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Total Earnings Card
                    _buildTotalEarningsCard(screenWidth),
                    SizedBox(height: screenHeight * 0.015),
                    // Location Row — tap to open "Use Current Location" / manual entry sheet
                    GestureDetector(
                      onTap: _showAddressBottomSheet,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: Text(
                              _currentAddress.isNotEmpty
                                  ? _currentAddress
                                  : (getmyProfile?.address ?? ""),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          (_isFetchingLocation || _isUpdatingAddress)
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // Job Calendar and QR Code Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.calendar_month,
                            label: "My job calendar",
                           onPressed: () {
                           
                   
                         Navigator.pushNamed(
                                 context,
                                  arguments: {
                            'provider_id' : ProviderId??""
                          },
                          Config.jobCalendarRouteName,
                         
                            
                           );
                               },

                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.qr_code,
                            label: "Show my QR code",
                            onPressed: () {
                              Navigator.pushNamed(context,
                              Config.showQRCodeRouteName);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Status Cards Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child:  GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: screenWidth * 0.04,
                mainAxisSpacing: screenHeight * 0.02,
                childAspectRatio:1.27,
                // ← NEW
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dashboardData["statusCards"].length,
              itemBuilder: (context, index) {
                var card = dashboardData["statusCards"][index];
                return _buildStatusCard(card, screenWidth);
              },
            ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Current Subscriptions Section
              _buildCurrentSubscriptionsSection(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.03),

              // Statistics Graph
              _buildStatisticsGraph(
                screenWidth,
                screenHeight,
                _getVisibleData(),
                selectedMonthName,
                selectedYear,
                _changeMonth,
                _currentIndex > 0, // canMoveBack
                _currentIndex < _allEarningsData.length - 1, // canMoveForward
              ),
              SizedBox(height: screenHeight * 0.03),

              // Offers Card Section
              // _buildOffersSection(screenWidth, screenHeight),
              // SizedBox(height: screenHeight * 0.02),
              _buildOffersCarousel(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.015),
              _buildPaginationDots(),
              SizedBox(height: screenHeight * 0.015),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusCard(String amount, String title, Color color) {
    return Container(
      height: 90, // Add this line for height
      width: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            amount,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard(double screenWidth) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // Left side Image
            Image.asset(
              "assets/images/coins.png",
              height: screenWidth * 0.18,
              width: screenWidth * 0.18,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: screenWidth * 0.18,
                  width: screenWidth * 0.18,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.monetization_on,
                    color: Colors.orange,
                    size: screenWidth * 0.1,
                  ),
                );
              },
            ),
            SizedBox(width: screenWidth * 0.04),

            // Right side container
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GB Coins row
                  Row(
                    children: [
                      const Text(
                        "GB Coins",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/gobuddyIcon.png",
                              width: 18,
                              height: 18,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.monetization_on,
                                  color: Colors.orange,
                                  size: 16,
                                );
                              },
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                mysummary?.gbcoins.toString() ?? "0",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: "₹ ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: dashboardData["totalEarnings"],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: " /${dashboardData["jobsGoal"]}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Button
                  SizedBox(
                    height: screenWidth * 0.08,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Total Earnings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.black),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.transparent, // Remove green tint
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _getImageFromString(String imageName, double size) {
    switch (imageName) {
      case "Current Month":
        return Image.asset(
          "assets/images/current_month.png",
          width: size,
          height: size,
          // Removed color property to keep original image colors
        );
      case "Pending Orders":
        return Image.asset(
          "assets/images/pending_orders.png",
          width: size,
          height: size,
        );
      case "Today Orders":
        return Image.asset(
          "assets/images/today_orders.png",
          width: size,
          height: size,
        );
      case "Missed Orders":
        return Image.asset(
          "assets/images/missed_orders.png",
          width: size,
          height: size,
        );
      default:
        return Image.asset(
          "assets/images/orders.png",
          width: size,
          height: size,
        );
    }
  }

  Widget _buildStatusCard(Map<String, dynamic> card, double screenWidth) {
   return GestureDetector(
     onTap: () {
       final title = card["title"] as String? ?? "";
       String targetTab = "Pending";
       if (title == "Pending Orders") {
         targetTab = "Pending";
       } else if (title == "Today Orders") {
         targetTab = "Open";
       } else if (title == "Current Month") {
         targetTab = "Completed";
       } else if (title == "Missed Orders") {
         targetTab = "Cancelled";
       }
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => MyOrdersScreen(initialTab: targetTab),
         ),
       ).then((_) {
         _getMyEarningsIncome();
         getAllServices();
       });
     },
     child: Container(
       padding: const EdgeInsets.all(14),
       decoration: BoxDecoration(
         color: Color(card["color"] as int),
         borderRadius: BorderRadius.circular(16),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisSize: MainAxisSize.min,           // ← IMPORTANT
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Flexible(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     FittedBox(                          // ← Prevent text overflow
                       child: Text(
                         "₹${card["amount"]}",
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: screenWidth * 0.05,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ),
                     FittedBox(
                       child: Text(
                         "(${card["count"]})",
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: screenWidth * 0.04,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ),
                   ],
                 ),
               ),

               Flexible(
                 child: _getImageFromString(
                   card["title"] as String,
                   screenWidth * 0.10,                 // ↓ make image smaller
                 ),
               ),
             ],
           ),

           const SizedBox(height: 8),

           Text(
             card["title"] as String,
             maxLines: 1,
             overflow: TextOverflow.ellipsis,        // ← Protect title
             style: TextStyle(
               color: Colors.white,
               fontSize: screenWidth * 0.042,
               fontWeight: FontWeight.w500,
             ),
           ),
         ],
       ),
     ),
   );
 }

  // Helper widget for a single subscription plan tile
Widget _buildSubscriptionPlanTile(
  Data data,
  double screenWidth,
  double screenHeight,
) {
  return Padding(
    padding: EdgeInsets.all(screenWidth * 0.04),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.subscription ?? "",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
        SizedBox(height: screenHeight * 0.005),
        Text("Jobs: ${data.jobs ?? 0}"),
        Text("Remaining: ${data.remaining ?? 0}"),
        Text("Used: ${data.used ?? 0}"),
        Text("Amount: ₹${data.amount ?? 0}"),
        SizedBox(height: screenHeight * 0.01),
        Text(
          "Status: ${data.statusText ?? ""}",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
  
  // Main function to build the subscriptions section
  Widget _buildCurrentSubscriptionsSection(
    double screenWidth,
    double screenHeight,
  ) {
   final subscriptions = getDashboardSubscriptionData;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Current Subscriptions and See All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Current Subscriptions",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Config.mySubscriptionsRouteName,
                    arguments: {'issubscription': true},
                  ).then((_) {
                    _getDashboardSubscriptions();
                    _getMyEarningsIncome();
                  });
                },
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),

          if (subscriptions.isEmpty)
            // Existing logic for No Active Subscription Card (untouched)
            // ... (No Active Subscription Card)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "No Active Subscription",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Please create your package",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () async {
                          final isVerified = await UtilClass.checkProviderApprovalLive();
                          if (!isVerified) {
                            _showVerificationPendingDialog();
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            Config.mySubscriptionsRouteName,
                            arguments: {'issubscription': false},
                          ).then((_) {
                            _getDashboardSubscriptions();
                            _getMyEarningsIncome();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: green,
                          side: BorderSide(color: green, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Create Package",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
       ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: subscriptions.length,
  itemBuilder: (context, index) {
    final data = subscriptions[index];

    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 🔶 CATEGORY HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.015,
              ),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  data.category ?? "",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 🔹 PLAN DETAILS
            _buildSubscriptionPlanTile(data, screenWidth, screenHeight),

            // 🔹 SERVICES LIST
            ...(data.services ?? []).map((service) {
              return ListTile(
                title: Text(
                  "Service ID: ${service.serviceId}",
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
                subtitle: Text(
                  "Price: ₹${service.price} | Used: ${service.usedJobs}",
                ),
              );
            }).toList(),

            // 🔻 VIEW MORE
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.01,
                bottom: screenHeight * 0.02,
              ),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Config.getActiveSubscriptionsRouteName,
                  ).then((_) {
                    _getDashboardSubscriptions();
                    _getMyEarningsIncome();
                  });
                },
                child: Text(
                  'View more',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: screenWidth * 0.038,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
)
       
        ],
      ),
    );
  }

  Widget _buildStatisticsGraph(
    double screenWidth,
    double screenHeight,
    List<Map<String, dynamic>> visibleEarningsData,
    String selectedMonthName,
    int selectedYear,
    Function(int) changeMonth,
    bool canMoveBack,
    bool canMoveForward,
  ) {
    const double maxScale = 100000.0; // Fixed max scale for Y-axis
    final graphHeight =
        screenHeight * 0.3; // Increased graph height for better visibility

    // Adjusted Y-axis labels and steps to match the image
    List<String> yLabels = [
      "₹ 0k",
      "₹ 10k",
      "₹ 20k",
      "₹ 30k",
      "₹ 40k",
      "₹ 50k",
      "₹ 60k",
      "₹ 70k",
      "₹ 80k",
      "₹ 90k",
      "₹ 100k",
    ];

    return Padding(
      padding: EdgeInsets.only(left: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Statistics",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          // Custom Calendar Header
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.008,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9), // Light Green background
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: canMoveBack ? () => changeMonth(-1) : null,
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: canMoveBack ? Colors.black : Colors.grey,
                      size: screenWidth * 0.045,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "$selectedMonthName, $selectedYear",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: canMoveForward ? () => changeMonth(1) : null,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: canMoveForward ? Colors.black : Colors.grey,
                      size: screenWidth * 0.045,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          // Graph Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Y-Axis Labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: yLabels.reversed
                    .map(
                      (label) => SizedBox(
                        height: (graphHeight / (yLabels.length - 1)),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            // Padding to separate from grid
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(width: screenWidth * 0.005), // Reduced space
              // Main Graph Area
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    height: graphHeight + screenHeight * 0.06,
                    // Extra space for labels and dot
                    width: max(
                      screenWidth * 0.85,
                      visibleEarningsData.length * screenWidth * 0.15,
                    ),
                    child: Stack(
                      children: [
                        // Horizontal Grid Lines
                        ...List.generate(yLabels.length, (index) {
                          final segmentHeight =
                              graphHeight / (yLabels.length - 1);
                          // The lines start from 0k (bottom) up to 100k (top)
                          final topPosition = index * segmentHeight;

                          return Positioned(
                            top: graphHeight - topPosition,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1,
                              color: index == 0
                                  ? Colors.black26
                                  : Colors.grey.shade200, // Blacker line for 0k
                            ),
                          );
                        }),

                        // Vertical Bars and Labels
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: visibleEarningsData.map((data) {
                              final earning = data["earning"].toDouble();
                              final month = data["month"];
                              final barHeight =
                                  (earning / maxScale) * graphHeight;
                              final isSelectedMonth =
                                  month == selectedMonthName;

                              return SizedBox(
                                width: screenWidth * 0.12,
                                // Fixed width for each bar column
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Earning Value Label (e.g., ₹63.000)
                                    if (earning > 0)
                                      Text(
                                        "₹${(earning / 1000).toStringAsFixed(3)}", // Format: ₹X.XXX
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    SizedBox(height: 4),
                                    // Bar
                                    Container(
                                      width: screenWidth * 0.08,
                                      height: max(barHeight, 0),
                                      decoration: BoxDecoration(
                                        color: green,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          topRight: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    // Month Label
                                    Text(
                                      month,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: isSelectedMonth
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                    // Orange Dot for Selected Month
                                    SizedBox(height: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSelectedMonth
                                            ? orange
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(double screenWidth, double screenHeight) {
    final offers = dashboardData["offers"] as List<dynamic>;

    return SizedBox(
      height: screenHeight * 0.16,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.04,
              right: index == offers.length - 1 ? screenWidth * 0.04 : 0,
            ),
            child: Container(
              width: screenWidth * 0.85,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: Color(offer["backgroundColor"] as int),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                offer["text"],
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.red,
                              size: 18,
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          offer["subText"],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Let's Create your package",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: screenWidth * 0.028,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        SizedBox(
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              offer["buttonText"],
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  // Offer Image
                  Expanded(
                    flex: 2,
                    child: Image.asset(
                      offer["imageAsset"],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image,
                            color: Colors.white,
                            size: screenWidth * 0.12,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Core Logic: Offer Carousel with Image Background ---
  // --- Core Logic: Offer Carousel with Dynamic Image ---
  // --- Core Logic: Offer Carousel with Dynamic Image and 40% Width ---
  // --- Core Logic: Offer Carousel with Dynamic Image and 80% Height ---
  Widget _buildOffersCarousel(double screenWidth, double screenHeight) {
    final offers = dashboardData["offers"] as List<dynamic>;

    if (offers.isEmpty) {
      return SizedBox(
        height: screenHeight * 0.18,
        child: Center(
          child: Text(
            "No offers available at the moment.",
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
        ),
      );
    }

    return SizedBox(
      height: screenHeight * 0.18, // Card Height
      child: PageView.builder(
        controller: _pageController,
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final String imagePath =
              offer["advertise"] ??
              'assets/images/default_offer.png'; 

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                // Use background color from JSON
                // ignore: deprecated_member_use
                color:Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // --- Offer Text and Button (Left Side - 60% Width) ---
                  Expanded(
                    flex: 3, // 60%
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                offer["title"],
                                style: TextStyle(
                                  color: textOrange,
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Flame icon (Orange)
                            const Icon(
                              Icons.local_fire_department,
                              color: textOrange,
                              size: 18,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          offer["sub_title"],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        // Text(
                        //   "Let's Create your package",
                        //   style: TextStyle(
                        //     color: Colors.white70,
                        //     fontSize: screenWidth * 0.028,
                        //   ),
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                        SizedBox(height: screenHeight * 0.01),
                        // SizedBox(
                        //   height: screenHeight * 0.04,
                        //   child: ElevatedButton(
                        //     onPressed: () {},
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.white,
                        //       foregroundColor: textOrange,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //       ),
                        //       padding: const EdgeInsets.symmetric(
                        //         horizontal: 16,
                        //       ),
                        //       elevation: 0,
                        //     ),
                        //     child: Text(
                        //      "Create",
                        //       style: TextStyle(
                        //         fontSize: screenWidth * 0.032,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),

                  // --- Image/Background (Right Side - 40% Width, 80% Height) ---
                  Expanded(
                    flex: 2, // 40%
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.bottomRight,
                      child: FractionallySizedBox(
                        heightFactor:
                            0.99, // Set image height to 80% of the available vertical space
                        child: Image.network(
                          imagePath, // Dynamic image path from JSON
                          fit: BoxFit.fitHeight,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.error,
                                color: Colors.white,
                                size: screenWidth * 0.12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Pagination Dots (Untouched from previous change) ---
  Widget _buildPaginationDots() {
    final offers = dashboardData["offers"] as List<dynamic>;
    if (offers.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        offers.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 6.0,
          width: _currentPage == index ? 20.0 : 6.0,
          decoration: BoxDecoration(
            color: _currentPage == index ? green : lightBlue,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}