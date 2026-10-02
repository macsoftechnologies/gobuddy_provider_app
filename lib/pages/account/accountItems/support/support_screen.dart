import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import '../../../../components/button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _issueTitleController = TextEditingController();
  final TextEditingController _issueDescriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Missing Information"),
          content: const Text("Please fill in both fields before submitting."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    dynamic userData = {};
    final userStr = Preferences.getUserDetails();
    if (userStr != null && userStr.isNotEmpty) {
      try {
        userData = json.decode(userStr);
      } catch (_) {}
    }

    final userId = (userData["user_id"] ?? userData["id"] ?? "").toString();

    UtilClass.showProgress(context: context);
    try {
      final response = await Repository.postApiService("${EndPoints.newbaseUrl}support", {
        "user_id": userId,
        "title": _issueTitleController.text.trim(),
        "description": _issueDescriptionController.text.trim(),
      });
      UtilClass.hideProgress();

      final parsed = response is String ? json.decode(response) : response;
      final msg = (parsed is Map ? parsed["message"] : null) ??
          "Your issue has been saved successfully and our support team will follow you shortly";

      _issueTitleController.clear();
      _issueDescriptionController.clear();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Support Request Submitted", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(msg),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      UtilClass.hideProgress();
      UtilClass.showAlertDialog(context: context, message: "Failed to submit support request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Support"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC8BB47), // Golden Yellow
                Color(0xFF25AC2C),], // 👈 Gradient colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.02,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Issue Title",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextFormField(
                controller: _issueTitleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "Enter the title of your issue",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter issue title";
                  }
                  return null;
                },
              ),
              SizedBox(height: screenHeight * 0.03),

              Text(
                "Describe the issue you have encountered",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextFormField(
                controller: _issueDescriptionController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "Describe your issue in detail",
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please describe the issue";
                  }
                  return null;
                },
              ),
              SizedBox(height: screenHeight * 0.05),

              GradientButton(
                onPressed: () {
                  _handleSubmit();
                },
                child: Text(
                  'Submit To Support',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
