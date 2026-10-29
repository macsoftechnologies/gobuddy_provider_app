import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../components/button.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/preferences.dart';
import '../../../../services/end_points.dart';
import '../../../../services/repository.dart';

class ReferAndEarnPage extends StatefulWidget {
  const ReferAndEarnPage({super.key});

  @override
  _ReferAndEarnPageState createState() => _ReferAndEarnPageState();
}

class _ReferAndEarnPageState extends State<ReferAndEarnPage> {
  String? referralCode;

  void _shareReferral() {
    String message = (referralCode != null && referralCode!.isNotEmpty)
        ? "Join GoBuddy Provider app with my referral code: $referralCode to receive exclusive jobs and earn more! Download now."
        : "Join GoBuddy Provider app to receive exclusive jobs and earn more! Download now.";
    Share.share(message);
  }

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null &&
        args.containsKey('referral_code') &&
        args['referral_code'] != null &&
        args['referral_code'].toString().trim().isNotEmpty) {
      setState(() {
        referralCode = args['referral_code'].toString().trim();
      });
    } else if (referralCode == null || referralCode!.isEmpty) {
      _loadReferralCode();
    }
  }

  Future<void> _loadReferralCode() async {
    // 1. Try local preferences
    try {
      final userStr = Preferences.getUserDetails();
      if (userStr != null && userStr.isNotEmpty) {
        final userData = json.decode(userStr);
        if (userData is Map) {
          final code = (userData['referral_id'] ?? userData['referral_code'])
              ?.toString()
              .trim();
          if (code != null && code.isNotEmpty) {
            if (mounted) {
              setState(() {
                referralCode = code;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading referral code from preferences: $e");
    }

    // 2. Fetch live profile from backend if still empty
    try {
      final userId = Preferences.getUserID();
      if (userId != null && userId.isNotEmpty) {
        final res = await Repository.postApiService(EndPoints.profile, {
          "user_id": userId,
        });
        if (res != null) {
          final parsed = json.decode(res);
          if (parsed is Map && parsed["status"] == "valid") {
            final p = parsed["profile"] ?? {};
            final code = (p['referral_id'] ?? p['referral_code'])?.toString().trim();
            if (code != null && code.isNotEmpty && mounted) {
              setState(() {
                referralCode = code;
              });
              try {
                final userStr = Preferences.getUserDetails();
                final userMap = userStr != null && userStr.isNotEmpty
                    ? (json.decode(userStr) as Map<String, dynamic>)
                    : <String, dynamic>{};
                if (p is Map) {
                  p.forEach((k, v) {
                    if (v != null) userMap[k.toString()] = v;
                  });
                }
                userMap["referral_id"] = code;
                Preferences.setUserDetails(json.encode(userMap));
              } catch (_) {}
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching live profile for referral code: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refer & Earn"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFC8BB47), // Golden Yellow
                Color(0xFF25AC2C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset("assets/images/referAndEarn.png", height: 200),
            const SizedBox(height: 30),
            Row(
              children: const [
                Icon(Icons.looks_one),
                SizedBox(width: 10),
                Expanded(child: Text("Refer a friend or family member")),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.looks_two),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "When they register or order:\nA. You receive 5 GB coins\nB. They get ₹100 off",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (referralCode != null && referralCode!.isNotEmpty)
                        ? referralCode!
                        : "Loading...",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (referralCode != null && referralCode!.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: referralCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Referral code copied to clipboard!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text("Copy"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            GradientButton(
              onPressed: () {
                _shareReferral();
              },
              child: Text(
                'Refer Now',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: deviceWidth * 0.04,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
