import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/custom_back_button.dart';
import '../../components/appcolor.dart';
import '../../components/dailogbox.dart';
import '../../utils/config.dart';

class EKYCVerificationPage extends StatefulWidget {
  const EKYCVerificationPage({super.key});

  @override
  _EKYCVerificationPageState createState() => _EKYCVerificationPageState();
}

class _EKYCVerificationPageState extends State<EKYCVerificationPage> {
  bool acceptConditions = false;
  final ImagePicker _picker = ImagePicker();

  // Store selected images
  File? aadharFront;
  File? aadharBack;
  File? panOrDl;
  File? skillCert1;
  File? skillCert2;

  dynamic userData= {};
  String? existingAadharFront;
  String? existingAadharBack;
  String? existingPanOrDl;

  Future<void> pickImage(Function(File) onSelected) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      onSelected(File(image.path));
    }
  }

  @override
  void initState() {
    super.initState();

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    _fetchExistingEkyc();
  }

  Future<void> _fetchExistingEkyc() async {
    final userId = userData["user_id"] ?? userData["id"];
    if (userId == null) return;
    try {
      final response = await Repository.postApiService(
        EndPoints.getEkycDetails,
        {"user_id": userId},
      );
      final dynamic parsed = response is String ? json.decode(response) : response;
      if (parsed != null && (parsed["status"] == "valid" || parsed["status"] == true)) {
        final data = parsed["data"] ?? parsed["ekyc"] ?? parsed;
        setState(() {
          if (data["aadhar_front"] != null && data["aadhar_front"].toString().isNotEmpty) {
            existingAadharFront = data["aadhar_front"].toString();
          }
          if (data["aadhar_back"] != null && data["aadhar_back"].toString().isNotEmpty) {
            existingAadharBack = data["aadhar_back"].toString();
          }
          if (data["pancard"] != null && data["pancard"].toString().isNotEmpty) {
            existingPanOrDl = data["pancard"].toString();
          }
        });
      }
    } catch (e) {
      print("Error fetching ekyc details: $e");
    }
  }

  Widget uploadBox(
    File? file,
    String? remoteUrl,
    String label,
    Function(File) onSelected, {
    VoidCallback? onRemove,
  }) {
    String? fullRemoteUrl;
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      fullRemoteUrl = UtilClass.formatImageUrl(remoteUrl);
    }

    final hasContent = file != null || fullRemoteUrl != null;

    return Stack(
      children: [
        GestureDetector(
          onTap: () => pickImage(onSelected),
          child: Container(
            height: 100,
            width: 130,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : (fullRemoteUrl != null
                      ? Image.network(
                          fullRemoteUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  "$label\n(Uploaded)",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.upload_file, color: Colors.green, size: 30),
                              const SizedBox(height: 4),
                              Text(label, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
            ),
          ),
        ),
        if (hasContent && onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  bool isFormValid() {
    return (aadharFront != null || (existingAadharFront != null && existingAadharFront!.isNotEmpty)) &&
        (aadharBack != null || (existingAadharBack != null && existingAadharBack!.isNotEmpty)) &&
        (panOrDl != null || (existingPanOrDl != null && existingPanOrDl!.isNotEmpty)) &&
        acceptConditions;
  }

  void _showFormValidationErrors() {
    List<String> missing = [];
    if (aadharFront == null && (existingAadharFront == null || existingAadharFront!.isEmpty)) {
      missing.add("• Aadhar Card Front image");
    }
    if (aadharBack == null && (existingAadharBack == null || existingAadharBack!.isEmpty)) {
      missing.add("• Aadhar Card Back image");
    }
    if (panOrDl == null && (existingPanOrDl == null || existingPanOrDl!.isEmpty)) {
      missing.add("• PAN Card or Driving License");
    }
    if (!acceptConditions) {
      missing.add("• Accept Validity Conditions checkbox");
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Required Documents Missing", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please provide all mandatory requirements before submitting:"),
            const SizedBox(height: 12),
            ...missing.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(item, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void callekycVeifyAPI() async {
    final userId = userData["user_id"]?.toString() ?? "";
    if (userId.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "User session expired or invalid. Please re-login.",
      );
      return;
    }
    Map<String, dynamic> uploadMap = {
      "user_id": userId,
      "document_type": "Aadhar",
    };

    if (aadharFront != null) {
      uploadMap["aadhar_front"] = await MultipartFile.fromFile(
        aadharFront!.path,
        filename: "aadhar_front.jpg",
      );
    }
    if (aadharBack != null) {
      uploadMap["aadhar_back"] = await MultipartFile.fromFile(
        aadharBack!.path,
        filename: "aadhar_back.jpg",
      );
    }
    if (panOrDl != null) {
      uploadMap["pancard"] = await MultipartFile.fromFile(
        panOrDl!.path,
        filename: "panOrDl.jpg",
      );
    }

    var formData = FormData.fromMap(uploadMap);

    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postimagesApiService(EndPoints.ekycApi, formData).then((
        value,
      ) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
          } else {
            // ignore: use_build_context_synchronously
            // UtilClass.showAlertDialog(
            //   // ignore: use_build_context_synchronously
            //   context: context,
            //   message: parsed["message"],
            // );
          }

          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final bool isFromAccount = args?['isFromAccount'] == true ||
              (Navigator.canPop(context) && (userData["admin_approval_provider"] != null || userData["token"] != null));

          showCustomDialog(
            // ignore: use_build_context_synchronously
            context: context,
            message: 'Documents Submitted Successfully!',
          );

          // Delay navigation by 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            // Dismiss the custom success dialog
            Navigator.of(context, rootNavigator: true).pop();

            if (isFromAccount) {
              // Return directly to My Documents screen
              Navigator.pop(context, true);
            } else {
              // Initial registration flow -> proceed to Registration Fee screen
              Navigator.pushReplacementNamed(
                context,
                Config.regiFeeRouteName,
              );
            }
          });
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
    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.verified_user, size: 60, color: Colors.green),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "e-KYC Verification",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Center(child: Text("Upload your documents below")),
              SizedBox(height: 20),

              sectionTitle("Upload your Aadhar:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      uploadBox(
                        aadharFront,
                        existingAadharFront,
                        "Front",
                        (file) {
                          setState(() => aadharFront = file);
                        },
                        onRemove: () {
                          setState(() {
                            aadharFront = null;
                            existingAadharFront = null;
                          });
                        },
                      ),
                      SizedBox(height: 5),
                      Text("Front side"),
                    ],
                  ),
                  Column(
                    children: [
                      uploadBox(
                        aadharBack,
                        existingAadharBack,
                        "Back",
                        (file) {
                          setState(() => aadharBack = file);
                        },
                        onRemove: () {
                          setState(() {
                            aadharBack = null;
                            existingAadharBack = null;
                          });
                        },
                      ),
                      SizedBox(height: 5),
                      Text("Back side"),
                    ],
                  ),
                ],
              ),

              sectionTitle("Upload PAN or Driving License :"),
              uploadBox(
                panOrDl,
                existingPanOrDl,
                "PAN/DL",
                (file) {
                  setState(() => panOrDl = file);
                },
                onRemove: () {
                  setState(() {
                    panOrDl = null;
                    existingPanOrDl = null;
                  });
                },
              ),

              sectionTitle(
                "Upload any skills or Training Certificates : (Optional)",
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  uploadBox(
                    skillCert1,
                    null,
                    "Skill 1",
                    (file) {
                      setState(() => skillCert1 = file);
                    },
                    onRemove: () {
                      setState(() => skillCert1 = null);
                    },
                  ),
                  uploadBox(
                    skillCert2,
                    null,
                    "Skill 2",
                    (file) {
                      setState(() => skillCert2 = file);
                    },
                    onRemove: () {
                      setState(() => skillCert2 = null);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: acceptConditions,
                    onChanged: (value) {
                      setState(() => acceptConditions = value ?? false);
                    },
                  ),
                  Text("Accept "),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "Validity Conditions",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: isFormValid()
                      ? AppColors.buttonGradient
                      : LinearGradient(
                          colors: [Colors.grey, Colors.grey[400]!],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (!isFormValid()) {
                      _showFormValidationErrors();
                      return;
                    }
                    callekycVeifyAPI();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
