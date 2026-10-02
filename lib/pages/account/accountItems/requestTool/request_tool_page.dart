import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/components/dailogbox.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:image_picker/image_picker.dart';

class RequestToolScreen extends StatefulWidget {
  const RequestToolScreen({super.key});

  @override
  State<RequestToolScreen> createState() => _RequestToolScreenState();
}

class _RequestToolScreenState extends State<RequestToolScreen> {
  final TextEditingController _toolNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;

  int _selectedTabIndex = 0; // 0 = Send Request, 1 = Requested Tools
  List<dynamic> toolsDetails = [];
  dynamic userData = {};

  @override
  void initState() {
    super.initState();
    _toolNameController.addListener(_updateButtonState);
    _descriptionController.addListener(_updateButtonState);

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    callGetToolsAPI();
  }

  @override
  void dispose() {
    _toolNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormComplete {
    return _toolNameController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _selectedImage != null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// API: Get requested tools
  void callGetToolsAPI() async {
    var internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
      return;
    }

    UtilClass.showProgress(context: context);

    try {
      final response = await Repository.postApiService(EndPoints.tools, {
        "user_id": userData["user_id"] ?? "",
      });

      UtilClass.hideProgress();
      final dynamic parsed = response is String ? json.decode(response) : response;

      if (parsed["status"] == "valid" && parsed["requesttools"] != null) {
        setState(() {
          toolsDetails = parsed["requesttools"];
        });
      } else {
        setState(() {
          toolsDetails = [];
        });
      }
    } catch (e) {
      UtilClass.hideProgress();
      print("Error fetching tools: $e");
      setState(() {
        toolsDetails = [];
      });
    }
  }

  /// API: Request tool with image upload
  void callRequestToolAPI() async {
    if (_selectedImage == null) return;

    var internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
      return;
    }

    UtilClass.showProgress(context: context);

    try {
      final fileName = _selectedImage!.path.split(RegExp(r'[/\\]')).last;

      final formData = FormData.fromMap({
        "user_id": userData["user_id"] ?? "",
        "tool_name": _toolNameController.text,
        "description": _descriptionController.text,
        "tool_image": await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: fileName,
        ),
      });

      final response = await Repository.postimagesApiService(EndPoints.addrequesttool, formData);

      UtilClass.hideProgress();

      final dynamic parsed = response is String ? json.decode(response) : response;

      if (parsed["status"] == "valid") {
        // Clear form
        setState(() {
          _toolNameController.clear();
          _descriptionController.clear();
          _selectedImage = null;
        });

        UtilClass.showAlertDialog(context: context, message: "Tool Added Successfully");
        callGetToolsAPI(); // refresh list
      } else {
        UtilClass.showAlertDialog(context: context, message: parsed["message"] ?? "Failed to add tool");
      }
    } catch (e) {
      UtilClass.hideProgress();
      print("Upload failed: $e");
      UtilClass.showAlertDialog(context: context, message: "Failed to upload tool. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.yellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Request Tool",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: deviceWidth * 0.04,
            vertical: deviceHeight * 0.02,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Column(
                        children: [
                          Text(
                            "Send Request",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 0 ? Colors.black : Colors.grey,
                            ),
                          ),
                          if (_selectedTabIndex == 0)
                            Container(height: 3, color: Colors.green, margin: const EdgeInsets.only(top: 4)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTabIndex = 1);
                        callGetToolsAPI();
                      },
                      child: Column(
                        children: [
                          Text(
                            "Requested Tools",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 1 ? Colors.black : Colors.grey,
                            ),
                          ),
                          if (_selectedTabIndex == 1)
                            Container(height: 3, color: Colors.green, margin: const EdgeInsets.only(top: 4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: deviceHeight * 0.02),
              _selectedTabIndex == 0
                  ? _buildSendRequestForm(deviceWidth, deviceHeight)
                  : _buildRequestedToolsList(deviceWidth, deviceHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendRequestForm(double deviceWidth, double deviceHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.04, vertical: deviceHeight * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tool Name", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          SizedBox(height: deviceHeight * 0.01),
          CustomInputField(controller: _toolNameController, hintText: "Enter Tool Name", maxLines: 1),
          SizedBox(height: deviceHeight * 0.02),
          const Text("Description", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          SizedBox(height: deviceHeight * 0.01),
          CustomInputField(controller: _descriptionController, hintText: "Enter Description", maxLines: 4),
          SizedBox(height: deviceHeight * 0.02),
          const Text("Tool Image", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          SizedBox(height: deviceHeight * 0.01),
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: deviceHeight * 0.15,
                  width: deviceWidth * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                  ),
                  child: _selectedImage == null ? const Icon(Icons.image, size: 40, color: Colors.grey) : null,
                ),
              ),
              SizedBox(width: deviceWidth * 0.04),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400)),
                  child: const Center(child: Icon(Icons.add, color: Colors.green)),
                ),
              ),
            ],
          ),
          SizedBox(height: deviceHeight * 0.03),
          CustomSubmitButton(deviceWidth: deviceWidth, text: "Submit", enabled: _isFormComplete, onTap: callRequestToolAPI),
        ],
      ),
    );
  }

  Widget _buildRequestedToolsList(double deviceWidth, double deviceHeight) {
    if (toolsDetails.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: deviceHeight * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handyman_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                "No requested tools yet",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var item in toolsDetails)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(deviceWidth * 0.04),
            margin: EdgeInsets.only(bottom: deviceHeight * 0.02),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: item["status"] == "1" ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      item["status"] == "1" ? "Accepted" : "Pending",
                      style: TextStyle(
                        color: item["status"] == "1" ? Colors.green : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Text("Tool Name", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Text(item["tool_name"] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: deviceHeight * 0.01),
                Text(item["description"] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                SizedBox(height: deviceHeight * 0.01),
                const Text("Tool Image", style: TextStyle(color: Colors.grey, fontSize: 14)),
                SizedBox(height: 8),
                Container(
                  height: deviceHeight * 0.1,
                  width: deviceWidth * 0.2,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey, width: 1.0)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.network(
                        UtilClass.formatImageUrl(item["tool_image"]?.toString()),
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.handyman, color: Colors.grey, size: 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Reusable Input Field Widget
class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;

  const CustomInputField({super.key, required this.controller, required this.hintText, required this.maxLines});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Reusable Submit Button Widget
class CustomSubmitButton extends StatelessWidget {
  final double deviceWidth;
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const CustomSubmitButton({super.key, required this.deviceWidth, required this.text, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: deviceWidth,
      height: 50,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(colors: [Colors.green, Colors.yellow], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(width: deviceWidth, height: 50, alignment: Alignment.center, child: Text(text, style: TextStyle(color: enabled ? Colors.white : Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500))),
        ),
      ),
    );
  }
}
