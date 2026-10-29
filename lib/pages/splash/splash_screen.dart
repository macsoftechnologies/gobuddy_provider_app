import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/my_colors.dart';
import 'package:gobuddy/utils/util_class.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  startTimer() {
    var duration = const Duration(seconds: 2);
    return Timer(duration, checkConditions);
  }

  Future<void> checkConditions() async {
    var user = Preferences.getUserDetails();
    if (user == null || user.trim().isEmpty) {
      navigateToLogin();
      return;
    }

    try {
      var decoded = json.decode(user);
      if (decoded == null || (decoded["user_id"] == null && decoded["id"] == null)) {
        navigateToLogin();
        return;
      }

      final userId = (decoded["user_id"] ?? decoded["id"]).toString().trim();
      if (userId.isEmpty) {
        navigateToLogin();
        return;
      }

      // 1. Fast cache check
      final ekycLocal = (decoded["ekyc"] ?? "").toString().trim();
      final feeLocal = (decoded["registration_fee"] ?? decoded["registration_fee_status"] ?? decoded["status"] ?? "").toString().trim();
      final adminLocal = (decoded["admin_approval_provider"] ?? "").toString().toLowerCase().trim();

      bool hasDocs = ekycLocal.isNotEmpty && ekycLocal != "0";
      bool isFeePaid = feeLocal == "1" || feeLocal == "true" || feeLocal == "paid";
      bool isApproved = adminLocal == "approved" || adminLocal == "1";

      // If already verified & approved in local cache, launch dashboard immediately
      if (hasDocs && isFeePaid && isApproved) {
        navigateToVendorHome();
        return;
      }

      // 2. Live verification check with timeout for accuracy
      final internet = await UtilClass.checkInternet();
      if (internet) {
        try {
          // Check KYC documents
          final ekycResp = await Repository.postApiService(
            EndPoints.getEkycDetails,
            {"user_id": userId},
          ).timeout(const Duration(seconds: 3));

          final dynamic parsedEkyc =
              ekycResp is String ? json.decode(ekycResp) : ekycResp;
          if (parsedEkyc != null &&
              (parsedEkyc["status"] == "success" ||
                  parsedEkyc["status"] == "valid" ||
                  parsedEkyc["status"] == true)) {
            final front = parsedEkyc["aadhar_front"] ?? parsedEkyc["data"]?["aadhar_front"];
            if (front != null && front.toString().trim().isNotEmpty) {
              hasDocs = true;
              decoded["ekyc"] = "1";
            } else {
              hasDocs = false;
              decoded["ekyc"] = "0";
            }
          } else {
            hasDocs = false;
            decoded["ekyc"] = "0";
          }
        } catch (_) {}

        try {
          // Check Profile & Payment
          final profResp = await Repository.postApiService(
            EndPoints.getProfileDetails,
            {"user_id": userId},
          ).timeout(const Duration(seconds: 3));

          final dynamic parsedProf =
              profResp is String ? json.decode(profResp) : profResp;
          if (parsedProf != null && parsedProf["status"] == "valid") {
            final p = parsedProf["profile"] ?? parsedProf["data"];
            if (p is Map) {
              p.forEach((k, v) {
                if (v != null) decoded[k.toString()] = v;
              });

              final adminStat = (p["admin_approval_provider"] ?? "").toString().toLowerCase().trim();
              final ekycStat = (p["ekyc_status"] ?? "").toString().toLowerCase().trim();
              final subCount = int.tryParse(parsedProf["subscription_count"]?.toString() ?? "0") ?? 0;
              final userDbStatus = (p["status"] ?? "").toString().trim();

              if (adminStat == "approved" || adminStat == "1") {
                isApproved = true;
                decoded["admin_approval_provider"] = "approved";
              }
              if (ekycStat == "1" || ekycStat == "approved") {
                hasDocs = true;
                decoded["ekyc"] = "1";
              }
              if (subCount > 0 || p["registration_fee"] == "1" || p["registration_fee_status"] == "1" || userDbStatus == "1") {
                isFeePaid = true;
                decoded["registration_fee"] = "1";
                decoded["registration_fee_status"] = "1";
              }
            }
          }
        } catch (_) {}

        Preferences.setUserDetails(json.encode(decoded));
      }

      if (!mounted) return;

      // 3. Routing decision:
      if (!hasDocs) {
        // User dropped off before uploading documents -> go to Document Verification
        Navigator.of(context).pushReplacementNamed(Config.ekycRouteName);
      } else if (!isFeePaid) {
        // User uploaded documents, but dropped off before paying fee -> go to Registration Fee
        Navigator.of(context).pushReplacementNamed(Config.regiFeeRouteName);
      } else {
        // Fully completed onboarding -> stay logged in and go to Dashboard
        navigateToVendorHome();
      }
    } catch (err) {
      if (!mounted) return;
      navigateToLogin();
    }
  }

  void navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(
      Config.onBoardRouteName,
    );
  }

  void navigateToVendorHome() {
    Navigator.of(context).pushReplacementNamed(
      Config.dashboardcRouteName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: HexColor(MyColors.white),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Image.asset("assets/images/logo.png"),
          ),
        ),
      ),
    );
  }
}