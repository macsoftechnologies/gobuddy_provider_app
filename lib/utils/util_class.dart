// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:hexcolor/hexcolor.dart';

import 'my_colors.dart';

class UtilClass {
  static Widget getSizedBox(var valueHeight, valueWidth) {
    return SizedBox(height: valueHeight, width: valueWidth);
  }

  static writeLog({
    required Response<dynamic> response,
    required FormData? formValues,
  }) {
    if (kDebugMode) {
      if (formValues != null) {
        log(
          "\n"
          'Response:  ${response.data}',
          name: response.realUri.toString(),
        );
        log("parameteres${formValues.fields}");
      } else {
        log(
          "\n"
          'Response:  ${response.data}',
          name: response.realUri.toString(),
        );
      }
    }
  }

  static Future<bool> checkInternet() async {
    final Connectivity connectivity = Connectivity();
    try {
      final List<ConnectivityResult> result =
          await connectivity.checkConnectivity();
      if (result.isEmpty) return false;
      return result.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other);
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static showProgress({required BuildContext context}) {
    SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.black);
    SVProgressHUD.show(status: Config.pleaseWait);
  }

  static hideProgress({BuildContext? context}) {
    SVProgressHUD.dismiss();
  }

  static showAlertDialog({
    required BuildContext context,
    required String? message,
    Function()? onOkClick,
  }) {
    UtilClass.hideProgress(context: context);
    Dialog alertDialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12.0),
                  topRight: Radius.circular(12.0),
                ),
                color: HexColor(MyColors.darkIndigo),
              ),
              alignment: Alignment.center,
              child: Text(
                Config.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                  fontFamily: Config.fontFamilyPoppinsBold,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              alignment: Alignment.center,
              child: Text(
                message ?? 'empty message',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: HexColor(MyColors.colorBlack),
                  fontFamily: Config.fontFamilyPoppinsMedium,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (onOkClick != null) {
                  await onOkClick();
                }
              },
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: HexColor(MyColors.darkIndigo),
                    fontSize: 18.0,
                    fontFamily: Config.fontFamilyPoppinsBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: alertDialog,
        );
      },
      barrierDismissible: false,
    );
  }

  static Future dialogueWithProceedCancelButton({
    required BuildContext context,
    required String title,
    required String msg,
    required String positiveBtnTitle,
    required String negativeBtnTitle,
    required Function()? onCancel,
    required Function()? onProceed,
  }) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          contentPadding: const EdgeInsets.only(top: 10.0),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title.isNotEmpty ? title : Config.appName,
                    style: TextStyle(
                      fontSize: 24.0,
                      color: HexColor(MyColors.colorBlack),
                      fontFamily: Config.fontFamilyPoppinsBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5.0),
              const Divider(color: Colors.grey, height: 4.0),
              const SizedBox(height: 15.0),
              Expanded(
                flex: 0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: Text(
                    msg,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: HexColor(MyColors.colorBlack),
                      fontFamily: Config.fontFamilyPoppinsMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              Padding(
                padding: const EdgeInsets.only(
                  left: 30.0,
                  right: 30.0,
                  top: 10,
                  bottom: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton(
                      onPressed: () async {
                        if (onCancel != null) {
                          await onCancel();
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        negativeBtnTitle.isNotEmpty
                            ? negativeBtnTitle
                            : Config.cancel,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                          fontFamily: Config.fontFamilyPoppinsBold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (onProceed != null) {
                          await onProceed();
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        positiveBtnTitle.isNotEmpty
                            ? positiveBtnTitle
                            : Config.submit,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: HexColor(MyColors.darkIndigo),
                          fontFamily: Config.fontFamilyPoppinsBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static bool isCheckPass(String value) {
    String passwordRegExp =
        r'^.*(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[a-z])(^[a-zA-Z0-9@\$=!:.#%]+$)';
    RegExp regExp = RegExp(passwordRegExp);
    bool isPasw = regExp.hasMatch(value);
    return isPasw;
  }

  static bool isCheckEmail(String value) {
    String emailRegExp =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(emailRegExp);
    bool isEml = regExp.hasMatch(value);
    return isEml;
  }

  static bool isValidateMobile(String value) {
    String pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    }
    return true;
  }

  static hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static printWrapped(String text) {
    final pattern = RegExp('.{1,800}');
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  /// Checks if a provider is approved by admin and/or has approved eKYC.
  /// Recognizes affirmative approval flags (e.g. ekyc_status_name == 'approved', ekyc_status == '1',
  /// admin_approval_provider == '1' / 'approved').
  /// Returns false only if explicitly rejected, or if all statuses indicate pending/unsubmitted review.
  static bool isProviderVerified(dynamic data, [dynamic ekycDocs]) {
    if (data == null) return false;

    String? adminApp;
    String? ekycStat;
    String? ekycName;
    bool? isVerCached;

    if (data is Map) {
      adminApp = data['admin_approval_provider']?.toString().trim().toLowerCase();
      ekycStat = data['ekyc_status']?.toString().trim().toLowerCase();
      ekycName = data['ekyc_status_name']?.toString().trim().toLowerCase();
      if (data['isVerified'] == true) isVerCached = true;
    }

    if (ekycDocs is Map) {
      if (ekycStat == null || ekycStat.isEmpty) {
        ekycStat = (ekycDocs['status'] ?? ekycDocs['ekyc_status'])?.toString().trim().toLowerCase();
      }
      if (ekycName == null || ekycName.isEmpty) {
        ekycName = (ekycDocs['status_name'] ?? ekycDocs['ekyc_status_name'])?.toString().trim().toLowerCase();
      }
      if (adminApp == null || adminApp.isEmpty) {
        adminApp = (ekycDocs['admin_approval_provider'] ?? ekycDocs['admin_approval'])?.toString().trim().toLowerCase();
      }
    }

    // 1. Explicit REJECTION: If explicitly marked rejected, provider is NOT verified
    if (adminApp == 'rejected' || ekycStat == 'rejected' || ekycName == 'rejected') {
      return false;
    }

    // 2. Affirmative APPROVAL by Admin or eKYC:
    final bool isAdminAppApproved =
        adminApp == '1' || adminApp == 'approved' || adminApp == 'active' || adminApp == 'yes';
    final bool isEkycNameApproved =
        ekycName == 'approved' || ekycName == 'verified' || ekycName == 'active';
    final bool isEkycStatApproved =
        ekycStat == '1' || ekycStat == 'approved' || ekycStat == 'valid';

    if (isAdminAppApproved || isEkycNameApproved || isEkycStatApproved) {
      return true;
    }

    // 3. Fallback: cached verified flag if not rejected or pending
    if (isVerCached == true &&
        ekycName != 'pending' &&
        ekycName != 'under review' &&
        ekycStat != 'pending' &&
        ekycStat != '0' &&
        adminApp != 'pending' &&
        adminApp != '0') {
      return true;
    }

    return false;
  }

  /// Shows the standard "Verification Under Review" modal popup with direct navigation to My Documents.
  static void showVerificationPendingDialog(BuildContext context) {
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

  /// Queries both profile and ekyc endpoints to get authoritative approval and document status.
  /// Automatically updates Preferences so the entire app is in sync.
  static Future<bool> checkProviderApprovalLive() async {
    try {
      final userVal = Preferences.getUserDetails();
      if (userVal == null) return false;
      final u = json.decode(userVal);
      final userId = u["user_id"] ?? u["id"];
      if (userId == null) return false;

      final results = await Future.wait([
        Repository.postApiService(
          EndPoints.getProfileDetails,
          {"user_id": userId.toString()},
        ),
        Repository.postApiService(
          EndPoints.getEkycDetails,
          {"user_id": userId.toString()},
        ),
      ]);

      final profileResp = results[0];
      final ekycResp = results[1];

      dynamic parsedProfile = profileResp is String ? json.decode(profileResp) : profileResp;
      dynamic parsedEkyc = ekycResp is String ? json.decode(ekycResp) : ekycResp;

      Map<String, dynamic> profMap = {};
      if (parsedProfile != null && (parsedProfile["status"] == "valid" || parsedProfile["status"] == true || parsedProfile["status"] == "success")) {
        final p = parsedProfile["profile"] ?? parsedProfile["data"] ?? parsedProfile;
        if (p is Map<String, dynamic>) {
          profMap = p;
        }
      }

      Map<String, dynamic> docMap = {};
      if (parsedEkyc != null && (parsedEkyc["status"] == "valid" || parsedEkyc["status"] == true || parsedEkyc["status"] == "success")) {
        final d = parsedEkyc["data"] ?? parsedEkyc["ekyc"] ?? parsedEkyc;
        if (d is Map<String, dynamic>) {
          docMap = d;
        }
      }

      final bool isApproved = isProviderVerified(profMap.isNotEmpty ? profMap : u, docMap);

      // Persist exact state to Preferences
      u['isVerified'] = isApproved;
      if (profMap['admin_approval_provider'] != null) {
        u['admin_approval_provider'] = profMap['admin_approval_provider'];
      }
      if (profMap['ekyc_status'] != null) {
        u['ekyc_status'] = profMap['ekyc_status'];
      }
      if (profMap['ekyc_status_name'] != null) {
        u['ekyc_status_name'] = profMap['ekyc_status_name'];
      }
      Preferences.setUserDetails(json.encode(u));
      return isApproved;
    } catch (_) {}

    // Fallback to cached data check if offline or request fails
    try {
      final userVal = Preferences.getUserDetails();
      if (userVal != null) {
        final u = json.decode(userVal);
        return isProviderVerified(u);
      }
    } catch (_) {}

    return false;
  }

  /// Formats profile and document image paths into complete valid URLs.
  /// Handles relative filenames, leading slashes, and ensures assets/images/ is included.
  static String formatProfileImageUrl(String? rawPath) {
    return formatImageUrl(rawPath);
  }

  /// Formats any image path (categories, subcategories, services, documents, profile) into complete valid encoded URLs.
  /// Handles relative filenames, cleans double slashes, maps obsolete admin.gobuddyindia.com domain to active dev domain, and encodes special characters.
  static String formatImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return "";
    String trimmed = rawPath.trim();

    // Fix obsolete or misconfigured admin domain to dev domain
    if (trimmed.contains("admin.gobuddyindia.com")) {
      trimmed = trimmed.replaceAll("admin.gobuddyindia.com", "dev.gobuddyindia.com");
    }

    // Handle full URLs
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      final schemeEnd = trimmed.indexOf("://") + 3;
      final scheme = trimmed.substring(0, schemeEnd);
      final rest = trimmed.substring(schemeEnd).replaceAll(RegExp(r'/+'), '/');
      return Uri.encodeFull("$scheme$rest");
    }

    String base = EndPoints.newbaseUrl.replaceAll('/api/', '/');
    if (!base.endsWith('/')) base = '$base/';

    trimmed = trimmed.replaceAll(RegExp(r'^/+'), '');
    if (trimmed.startsWith('assets/images/')) {
      trimmed = trimmed.substring('assets/images/'.length);
    }
    trimmed = trimmed.replaceAll(RegExp(r'^/+'), '');

    return Uri.encodeFull("${base}assets/images/$trimmed");
  }
}

