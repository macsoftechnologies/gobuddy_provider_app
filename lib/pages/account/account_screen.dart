import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/pages/authentication/login/login_screen.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';

// import '../../utils/config.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';
// import 'package:providerapp_gobuddy/screens/referandearnpage.dart';
// import 'package:providerapp_gobuddy/screens/requesttoolpage.dart';
// import 'package:providerapp_gobuddy/screens/subscriptionScreens/create_subscription.dart';
// import 'package:providerapp_gobuddy/screens/subscriptionscreen.dart';
// import 'package:providerapp_gobuddy/screens/viewprofilepage.dart';
//
// import 'loginscreen.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // A reusable builder for the list tiles
  dynamic profileDetails = {};
  dynamic userData = {};
  dynamic subscriptionCount = 0;
  @override
  void initState() {
    super.initState();

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    callgetProfileAPI();
  }

  void callgetProfileAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      final String userId = (profileDetails["id"] ??
              profileDetails["user_id"] ??
              userData["user_id"] ??
              userData["id"] ??
              Preferences.getUserID() ??
              "")
          .toString()
          .trim();
      if (userId.isEmpty) return;

      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.profile, {
        "user_id": userId,
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            final p = parsed["profile"] ?? {};
            setState(() {
              subscriptionCount = parsed["subscription_count"];
              profileDetails = p;
            });
            try {
              final userMap = Map<String, dynamic>.from(userData ?? {});
              if (p is Map) {
                p.forEach((k, v) {
                  if (v != null) userMap[k.toString()] = v;
                });
              }
              userMap["user_id"] = userId;
              Preferences.setUserDetails(json.encode(userMap));
              if (p["name"] != null && p["name"].toString().isNotEmpty) {
                Preferences.setName(p["name"].toString());
              }
              userData = userMap;
            } catch (_) {}
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text("Yes", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final String userId = (profileDetails["id"] ??
            profileDetails["user_id"] ??
            userData["user_id"] ??
            userData["id"] ??
            Preferences.getUserID() ??
            "")
        .toString();

    if (userId.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "User ID not found. Please log in again.",
      );
      return;
    }

    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: Config.kNoInternet,
        );
      }
      return;
    }

    if (mounted) {
      UtilClass.showProgress(context: context);
    }

    try {
      final response = await Repository.postApiService(
        EndPoints.inactiveUser,
        {"id": userId},
      );

      UtilClass.hideProgress();

      final parsed = response is String ? json.decode(response) : response;

      if (parsed != null &&
          (parsed["status"] == "valid" || parsed["status"] == true)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your account has been successfully deleted"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        await Preferences.initSharedPreference();
        await Preferences.clearPreference();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (Route route) => false,
        );
      } else {
        if (mounted) {
          UtilClass.showAlertDialog(
            context: context,
            message: parsed?["message"] ??
                "Failed to deactivate user. Please try again.",
          );
        }
      }
    } catch (e) {
      UtilClass.hideProgress();
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Internal Server Error. Please try again.",
        );
      }
    }
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    Color color = Colors.black,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double cardPadding = deviceWidth * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient and header
          Container(
            height: deviceHeight * 0.28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC8BB47), 
                  Color(0xFF25AC2C),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0, bottom: 24.0),
                    child: Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // User Profile Card
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: deviceWidth * 0.05,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile image with checkmark icon
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: deviceWidth * 0.08,
                                    backgroundColor: Colors.grey.shade200,
                                    child: ClipOval(
                                      child: (() {
                                        final String profileImg = (profileDetails['profile'] != null &&
                                                profileDetails['profile'].toString().trim().isNotEmpty)
                                            ? profileDetails['profile'].toString().trim()
                                            : (userData['profile'] ?? userData['profile_image'] ?? '')
                                                .toString()
                                                .trim();
                                        if (profileImg.isNotEmpty) {
                                          return Image.network(
                                            UtilClass.formatProfileImageUrl(profileImg),
                                            width: deviceWidth * 0.16,
                                            height: deviceWidth * 0.16,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                size: 36,
                                                color: Colors.grey,
                                              );
                                            },
                                          );
                                        }
                                        return const Icon(
                                          Icons.person,
                                          size: 36,
                                          color: Colors.grey,
                                        );
                                      })(),
                                    ),
                                  ),

                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: deviceWidth * 0.04),
                              // User details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
     Text(
  (profileDetails["name"] != null && profileDetails["name"].toString().trim().isNotEmpty)
      ? profileDetails["name"].toString()
      : (userData["name"] ?? Preferences.getName() ?? "Provider"),
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

  SizedBox(height: deviceHeight * 0.005),
     Text(
  "Profession : ${profileDetails['technician_category']?.isNotEmpty == true
      ? profileDetails['technician_category']
      : 'Provider'}",
  style: const TextStyle(
    fontSize: 14,
    color: Colors.grey,
  ),
),

                                    SizedBox(height: deviceHeight * 0.005),
                                    Text(
   "Referral Id : ${(profileDetails['referral_id'] != null && profileDetails['referral_id'].toString().isNotEmpty) ? profileDetails['referral_id'] : (profileDetails['referral_code'] ?? '')}",
   style: const TextStyle(
     fontSize: 14,
     color: Colors.black,
   ),
 ),

                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: deviceHeight * 0.02),
                          // GB Coins section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                'GB Coins',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white, // 👈 White background
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Color(
                                      0xFFFFD050,
                                    ), // 👈 Yellow border
                                    width: 1, // Border thickness
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.monetization_on,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      (profileDetails != null && profileDetails["gb_coins"] != null)
                                          ? profileDetails["gb_coins"].toString()
                                          : (userData["coins"] ?? userData["gb_coins"] ?? '0').toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Menu options
                  SizedBox(height: deviceHeight * 0.02),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.person_outline,
                    "View Profile",
                    onTap: () {
                      // Navigator.pushNamed(context, Config.viewProfileRouteName);

                      Navigator.pushNamed(
                        // ignore: use_build_context_synchronously
                        context,
                        Config.viewProfileRouteName,
                      ).then((value) {
                        callgetProfileAPI();
                      });
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.assignment_ind_outlined,
                    "My Documents",
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Config.myDocumentsRouteName,
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.subscriptions_outlined,
                    "My Subscriptions",
                    onTap: () {
                      if (subscriptionCount > 0) {
                        Navigator.pushNamed(
                          context,
                          Config.mySubscriptionsRouteName,
                          arguments: {"issubscription": true},
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          Config.mySubscriptionsRouteName,
                          arguments: {"issubscription": false},
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.description_outlined,
                    "Terms & Conditions",
                    onTap: () {
                      // Handle tap
                      Navigator.pushNamed(
                        context,
                        Config.termsConditionsRouteName,
                        //notificationsRouteName
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.shield_outlined,
                    "Privacy & Policy",
                    onTap: () {
                      // Handle tap
                      Navigator.pushNamed(
                        context,
                        Config
                            .privacyPolicyRouteName, //customerReviewsRouteName
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.support_agent_outlined,
                    "Support",
                    onTap: () {
                      // Handle tap
                      Navigator.pushNamed(
                        context,
                        Config.supportRouteName, 
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
  Icons.emoji_events_outlined,
  "Refer & Earn",
  onTap: () {
    Navigator.pushNamed(
      context,
      Config.referEarnRouteName,
      arguments: {
        'referral_code': (profileDetails['referral_id'] != null && profileDetails['referral_id'].toString().isNotEmpty)
            ? profileDetails['referral_id']
            : (profileDetails['referral_code'] ?? userData['referral_id'] ?? userData['referral_code'] ?? ""),
      },
    );
  },
),

                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.handyman_outlined,
                    "Request Tool",
                    onTap: () {
                      Navigator.pushNamed(context, Config.requestToolRouteName);
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.delete_outline,
                    "Delete Account",
                    color: Colors.red,
                    onTap: () {
                      _showDeleteAccountDialog();
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildListTile(
                    Icons.logout,
                    "Logout",
                    color: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Logout"),
                            content: const Text(
                              "Are you sure you want to logout?",
                            ),
                            actions: [
                              TextButton(
                                child: const Text("No"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text("Yes"),
                                onPressed: () {
                                  // Navigator.of(context).pushReplacementNamed(
                                  //   Config.loginRouteName,);

                                  Preferences.initSharedPreference();

                                  Preferences.clearPreference();

                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(),
                                    ),
                                    (Route route) => false,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
