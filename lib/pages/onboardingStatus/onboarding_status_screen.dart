import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';

class OnboardingStatusScreen extends StatefulWidget {
  const OnboardingStatusScreen({super.key});

  @override
  State<OnboardingStatusScreen> createState() => _OnboardingStatusScreenState();
}

class _OnboardingStatusScreenState extends State<OnboardingStatusScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  bool _hasEkyc = false;
  bool _isFeePaid = false;
  bool _isApproved = false;
  String _providerName = '';
  String _providerPhone = '';

  @override
  void initState() {
    super.initState();
    _loadLocalUserData();
    _fetchLiveStatus();
  }

  void _loadLocalUserData() {
    final userStr = Preferences.getUserDetails();
    if (userStr != null && userStr.trim().isNotEmpty) {
      try {
        final decoded = json.decode(userStr);
        if (decoded is Map) {
          _userData = Map<String, dynamic>.from(decoded);
          _parseUserFields(_userData);
        }
      } catch (e) {
        debugPrint("Error decoding local user data: $e");
      }
    }
  }

  void _parseUserFields(Map<String, dynamic> data) {
    _providerName = (data["name"] ?? data["user_name"] ?? "Service Provider").toString();
    _providerPhone = (data["phone_number"] ?? data["phone"] ?? "").toString();

    final ekycVal = (data["ekyc"] ?? "").toString().trim();
    final ekycStat = (data["ekyc_status"] ?? "").toString().trim().toLowerCase();
    final ekycName = (data["ekyc_status_name"] ?? "").toString().trim().toLowerCase();
    _hasEkyc = (ekycVal.isNotEmpty && ekycVal != "0") ||
        ekycStat == "0" || ekycStat == "1" ||
        ekycName == "pending" || ekycName == "approved";

    final feeVal = (data["registration_fee"] ?? data["registration_fee_status"] ?? data["status"] ?? "").toString();
    _isFeePaid = feeVal == "1" || feeVal == "true" || feeVal == "paid";

    final adminApproval = (data["admin_approval_provider"] ?? "").toString().toLowerCase().trim();
    _isApproved = adminApproval == "approved" || adminApproval == "1";
  }

  Future<void> _fetchLiveStatus() async {
    final userId = (_userData["user_id"] ?? _userData["id"] ?? "").toString();
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final profileResp = await Repository.postApiService(
        EndPoints.getProfileDetails,
        {"user_id": userId},
      );

      final dynamic parsedProfile =
          profileResp is String ? json.decode(profileResp) : profileResp;

      if (parsedProfile != null && parsedProfile["status"] == "valid") {
        final p = parsedProfile["profile"] ?? parsedProfile["data"];
        if (p is Map) {
          p.forEach((k, v) {
            if (v != null) _userData[k.toString()] = v;
          });

          final subCount = int.tryParse(
                  parsedProfile["subscription_count"]?.toString() ?? "0") ??
              0;
          final userDbStatus = (p["status"] ?? "").toString().trim();
          if (subCount > 0 || userDbStatus == "1") {
            _userData["registration_fee"] = "1";
            _userData["registration_fee_status"] = "1";
          }

          final pEkycStat = (p["ekyc_status"] ?? "").toString().trim().toLowerCase();
          final pEkycName = (p["ekyc_status_name"] ?? "").toString().trim().toLowerCase();
          if (pEkycStat == "0" || pEkycStat == "1" || pEkycName == "pending" || pEkycName == "approved") {
            _userData["ekyc"] = "1";
          }

          Preferences.setUserDetails(json.encode(_userData));
          _parseUserFields(_userData);
        }
      }

      // Check KYC details if still not marked
      if (!_hasEkyc) {
        final ekycResp = await Repository.postApiService(
          EndPoints.getEkycDetails,
          {"user_id": userId},
        );
        final dynamic parsedEkyc =
            ekycResp is String ? json.decode(ekycResp) : ekycResp;

        if (parsedEkyc != null &&
            (parsedEkyc["status"] == "success" ||
                parsedEkyc["status"] == "valid" ||
                parsedEkyc["status"] == true)) {
          final front = parsedEkyc["aadhar_front"] ??
              parsedEkyc["data"]?["aadhar_front"];
          if (front != null && front.toString().trim().isNotEmpty) {
            _hasEkyc = true;
            _userData["ekyc"] = "1";
            Preferences.setUserDetails(json.encode(_userData));
          }
        }
      }

      // If everything is already complete and approved, auto-navigate to Dashboard
      if (_hasEkyc && _isFeePaid && _isApproved && mounted) {
        Navigator.of(context).pushReplacementNamed(Config.dashboardcRouteName);
        return;
      }
    } catch (e) {
      debugPrint("Error fetching live onboarding status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBackPress() async {
    final bool? exitApp = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text("Exit GoBuddy?"),
          ],
        ),
        content: const Text(
          "Your progress is saved. You can reopen the app at any time to continue your account setup.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Stay", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Exit App", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (exitApp == true) {
      SystemNavigator.pop();
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out"),
        content: const Text(
          "Are you sure you want to log out of your provider account?",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Preferences.initSharedPreference();
              await Preferences.clearPreference();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                Config.loginRouteName,
                (route) => false,
              );
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSwitchAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.switch_account_outlined, color: Color(0xFF141C54)),
            SizedBox(width: 8),
            Text("Switch Account?"),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out and switch to another account? Any progress for the current account is safely saved on the server.",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Log Out & Switch", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Preferences.initSharedPreference();
      await Preferences.clearPreference();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        Config.loginRouteName,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackPress();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141C54),
          elevation: 0,
          title: const Text(
            "Account Setup Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: "Refresh Status",
              onPressed: () {
                _fetchLiveStatus();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: "Log Out",
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
            : RefreshIndicator(
                color: const Color(0xFF4CAF50),
                onRefresh: _fetchLiveStatus,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider Profile Card
                      _buildProfileCard(screenWidth),
                      const SizedBox(height: 20),

                      // Section Title
                      const Text(
                        "Onboarding Progress",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF141C54),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Step 1: Mobile & Registration
                      _buildStepTile(
                        stepNumber: "1",
                        title: "Account Registration",
                        subtitle: "Phone number & profile details registered",
                        isCompleted: true,
                        isActionable: false,
                        statusText: "Completed",
                      ),
                      const SizedBox(height: 12),

                      // Step 2: eKYC Document Verification
                      _buildStepTile(
                        stepNumber: "2",
                        title: "Document Verification (eKYC)",
                        subtitle: _hasEkyc
                            ? "Aadhaar & identity documents submitted"
                            : "Upload your Aadhaar & identity documents to verify identity",
                        isCompleted: _hasEkyc,
                        isActionable: !_hasEkyc,
                        statusText: _hasEkyc ? "Submitted" : "Pending",
                        buttonText: "Upload Documents",
                        onAction: () {
                          Navigator.pushNamed(context, Config.ekycRouteName)
                              .then((_) => _fetchLiveStatus());
                        },
                      ),
                      const SizedBox(height: 12),

                      // Step 3: One-Time Registration Fee
                      _buildStepTile(
                        stepNumber: "3",
                        title: "One-Time Registration Fee",
                        subtitle: _isFeePaid
                            ? "One-time registration fee payment verified"
                            : "Pay one-time registration fee of ₹300 to activate provider profile",
                        isCompleted: _isFeePaid,
                        isActionable: !_isFeePaid,
                        statusText: _isFeePaid ? "Paid" : "Pending",
                        buttonText: "Pay Registration Fee (₹300)",
                        onAction: () {
                          Navigator.pushNamed(context, Config.regiFeeRouteName)
                              .then((_) => _fetchLiveStatus());
                        },
                      ),
                      const SizedBox(height: 12),

                      // Step 4: Admin Approval & Activation
                      _buildStepTile(
                        stepNumber: "4",
                        title: "Admin Approval & Activation",
                        subtitle: _isApproved
                            ? "Profile approved! You can now access dashboard and receive job requests"
                            : (_hasEkyc && _isFeePaid)
                                ? "Our team is reviewing your profile. Activation usually takes 1-2 business days."
                                : "Pending completion of previous steps",
                        isCompleted: _isApproved,
                        isActionable: _isApproved || (_hasEkyc && _isFeePaid),
                        statusText: _isApproved
                            ? "Approved"
                            : (_hasEkyc && _isFeePaid)
                                ? "Under Review"
                                : "Waiting",
                        statusColor: _isApproved
                            ? Colors.green
                            : (_hasEkyc && _isFeePaid)
                                ? Colors.orange
                                : Colors.grey,
                        buttonText: _isApproved ? "Go to Dashboard" : null,
                        onAction: _isApproved
                            ? () {
                                Navigator.of(context).pushReplacementNamed(
                                    Config.dashboardcRouteName);
                              }
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Help & Support Card
                      _buildSupportCard(),
                      const SizedBox(height: 16),

                      // Switch Account / Register New Account Card
                      _buildSwitchAccountSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileCard(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            child: const Icon(
              Icons.person,
              size: 32,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _providerName.isNotEmpty ? _providerName : "Service Provider",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF141C54),
                  ),
                ),
                const SizedBox(height: 4),
                if (_providerPhone.isNotEmpty)
                  Text(
                    "+91 $_providerPhone",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isApproved
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isApproved
                        ? "Account Active"
                        : (_hasEkyc && _isFeePaid)
                            ? "Verification Under Review"
                            : "Setup Incomplete",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isApproved ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActionable,
    required String statusText,
    Color? statusColor,
    String? buttonText,
    VoidCallback? onAction,
  }) {
    final effectiveColor = statusColor ??
        (isCompleted
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF8C5E));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF141C54).withValues(alpha: 0.08),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          stepNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF141C54),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF141C54),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
          if (isActionable && buttonText != null && onAction != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? const Color(0xFF141C54)
                        : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: onAction,
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Color(0xFF141C54),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Need Assistance?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF141C54),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Contact GoBuddy Support: +91 9177746889",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchAccountSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Using a Different Account?",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF141C54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "If you want to sign in with a different phone number or register as a new service provider on this device, you can log out and start over. Your current progress is saved.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.switch_account_outlined, size: 20),
              label: const Text(
                "Switch Account / Start New Registration",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _handleSwitchAccount,
            ),
          ),
        ],
      ),
    );
  }
}
