import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/components/custom_back_button.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _ekycData = {};
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndDocuments();
  }

  Future<void> _loadUserAndDocuments() async {
    final userVal = Preferences.getUserDetails();
    if (userVal != null) {
      try {
        _userData = json.decode(userVal);
        _isVerified = UtilClass.isProviderVerified(_userData);
      } catch (_) {}
    }
    await _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hasNet = await UtilClass.checkInternet();
    if (!hasNet) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = Config.kNoInternet;
        });
      }
      return;
    }

    final userId = _userData['user_id'] ?? _userData['id'];
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User session expired. Please log in again.";
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        Repository.postApiService(
          EndPoints.getEkycDetails,
          {"user_id": userId.toString()},
        ),
        Repository.postApiService(
          EndPoints.getProfileDetails,
          {"user_id": userId.toString()},
        ),
      ]);

      final ekycResp = results[0];
      final profileResp = results[1];

      dynamic parsedEkyc = ekycResp is String ? json.decode(ekycResp) : ekycResp;
      dynamic parsedProfile = profileResp is String ? json.decode(profileResp) : profileResp;

      Map<String, dynamic> docData = {};
      if (parsedEkyc != null &&
          (parsedEkyc["status"] == "valid" ||
              parsedEkyc["status"] == true ||
              parsedEkyc["status"] == "success")) {
        final d = parsedEkyc["data"] ?? parsedEkyc["ekyc"] ?? parsedEkyc;
        if (d is Map<String, dynamic>) {
          docData = d;
        }
      }

      Map<String, dynamic> profData = {};
      if (parsedProfile != null &&
          (parsedProfile["status"] == "valid" ||
              parsedProfile["status"] == true ||
              parsedProfile["status"] == "success")) {
        final p = parsedProfile["profile"] ?? parsedProfile["data"] ?? parsedProfile;
        if (p is Map<String, dynamic>) {
          profData = p;
        }
      }

      final bool isApproved =
          UtilClass.isProviderVerified(profData.isNotEmpty ? profData : _userData, docData);

      if (mounted) {
        setState(() {
          _ekycData = docData;
          _isVerified = isApproved;
          _isLoading = false;
        });
      }

      // Persist verified state into Preferences so other screens know provider is approved
      try {
        _userData['isVerified'] = isApproved;
        if (profData['admin_approval_provider'] != null) {
          _userData['admin_approval_provider'] = profData['admin_approval_provider'];
        }
        if (profData['ekyc_status'] != null) {
          _userData['ekyc_status'] = profData['ekyc_status'];
        }
        if (profData['ekyc_status_name'] != null) {
          _userData['ekyc_status_name'] = profData['ekyc_status_name'];
        }
        Preferences.setUserDetails(json.encode(_userData));
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Something went wrong while fetching documents.";
        });
      }
    }
  }

  String _formatImageUrl(String? rawUrl) {
    return UtilClass.formatImageUrl(rawUrl);
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          "Failed to load image preview",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              width: double.infinity,
              child: const Text(
                "Pinch to zoom / drag to inspect",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required String subtitle,
    required String? rawUrl,
    required IconData icon,
  }) {
    final fullUrl = _formatImageUrl(rawUrl);
    final hasImage = fullUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? (_isVerified
                            ? Colors.green.shade50
                            : Colors.orange.shade50)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasImage
                          ? (_isVerified
                              ? Colors.green.shade300
                              : Colors.orange.shade300)
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    hasImage
                        ? (_isVerified ? "Approved" : "Under Review")
                        : "Missing",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasImage
                          ? (_isVerified
                              ? Colors.green.shade800
                              : Colors.orange.shade800)
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasImage)
              GestureDetector(
                onTap: () => _showImageDialog(context, fullUrl, title),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4CAF50),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 6),
                                Text(
                                  "Document Uploaded (Preview Unavailable)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Tap to inspect",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Config.ekycRouteName,
                    arguments: {'isFromAccount': true},
                  ).then((_) => _fetchDocuments());
                },
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "No document uploaded yet • Tap to upload",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const CustomBackButton(),
        title: const Text(
          "My Documents",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDocuments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF4CAF50),
                  onRefresh: _fetchDocuments,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Status Banner
                      Builder(builder: (context) {
                        final aFront = (_ekycData["aadhar_front"] ?? '').toString().trim();
                        final pan = (_ekycData["pancard"] ?? '').toString().trim();
                        final bool hasMandatoryDocs = aFront.isNotEmpty && pan.isNotEmpty;

                        final String bannerTitle = _isVerified
                            ? "Account Verified"
                            : (hasMandatoryDocs
                                ? "Verification Under Review"
                                : "Documents Required");

                        final String bannerSubtitle = _isVerified
                            ? "All your identity documents are approved. You can purchase subscriptions and accept orders."
                            : (hasMandatoryDocs
                                ? "Your identity documents are undergoing verification. Admin approval is required before creating packages or purchasing subscriptions."
                                : "Please upload your Aadhaar Card and PAN Card / Driving License to submit your account for verification.");

                        final IconData bannerIcon = _isVerified
                            ? Icons.verified
                            : (hasMandatoryDocs
                                ? Icons.hourglass_top
                                : Icons.assignment_late_outlined);

                        final List<Color> gradientColors = _isVerified
                            ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
                            : (hasMandatoryDocs
                                ? [const Color(0xFFE65100), const Color(0xFFFFA726)]
                                : [const Color(0xFFC62828), const Color(0xFFE53935)]);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradientColors),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors.first.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                bannerIcon,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bannerTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bannerSubtitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),

                      // Document Cards
                      _buildDocCard(
                        title: "Aadhaar Card (Front)",
                        subtitle: "Government Identity Proof",
                        rawUrl: _ekycData["aadhar_front"]?.toString(),
                        icon: Icons.badge_outlined,
                      ),
                      _buildDocCard(
                        title: "Aadhaar Card (Back)",
                        subtitle: "Address & Demographic Details",
                        rawUrl: _ekycData["aadhar_back"]?.toString(),
                        icon: Icons.badge_outlined,
                      ),
                      _buildDocCard(
                        title: "PAN Card / Driving License",
                        subtitle: "Tax Identification / License",
                        rawUrl: _ekycData["pancard"]?.toString(),
                        icon: Icons.credit_card_outlined,
                      ),
                      if (_ekycData["skill_cert1"] != null &&
                          _ekycData["skill_cert1"].toString().isNotEmpty)
                        _buildDocCard(
                          title: "Skill Certificate",
                          subtitle: "Trade & Professional Accreditation",
                          rawUrl: _ekycData["skill_cert1"]?.toString(),
                          icon: Icons.workspace_premium_outlined,
                        ),

                      const SizedBox(height: 10),

                      // Action Button (Upload / Re-upload)
                      if (!_isVerified)
                        Builder(builder: (context) {
                          final aFront = (_ekycData["aadhar_front"] ?? '').toString().trim();
                          final pan = (_ekycData["pancard"] ?? '').toString().trim();
                          final bool hasMandatoryDocs = aFront.isNotEmpty && pan.isNotEmpty;

                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: hasMandatoryDocs
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE53935),
                                side: BorderSide(
                                  color: hasMandatoryDocs
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFE53935),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(hasMandatoryDocs
                                  ? Icons.cloud_upload_outlined
                                  : Icons.upload_file),
                              label: Text(
                                hasMandatoryDocs
                                    ? "Update / Re-upload Documents"
                                    : "Upload Required Documents",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  Config.ekycRouteName,
                                  arguments: {'isFromAccount': true},
                                ).then((_) => _fetchDocuments());
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}
