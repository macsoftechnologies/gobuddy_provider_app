import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/qr_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:image_picker/image_picker.dart';

class MyQRCodeScreen extends StatefulWidget {
  const MyQRCodeScreen({Key? key}) : super(key: key);

  @override
  State<MyQRCodeScreen> createState() => _MyQRCodeScreenState();
}

class _MyQRCodeScreenState extends State<MyQRCodeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? myQrCodeImage;
  GetMyQrModel? myQrModel;

  Map<String, dynamic> userData = {};
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user data
  Future<void> _loadUserData() async {
    final userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    await callGetProfileAPI();
    await _getQrCodeImage();
  }

  /// Get profile API
  Future<void> callGetProfileAPI() async {
    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
      return;
    }

    final response = await Repository.postApiService(
      EndPoints.profile,
      {"user_id": userData["user_id"] ?? ""},
    );

    final parsed = json.decode(response);
    if (parsed["status"] == "valid") {
      setState(() {
        userData.addAll(parsed["profile"]);
      });
    }
  }

  /// Get QR Code from API
  Future<void> _getQrCodeImage() async {
    if (!await UtilClass.checkInternet()) return;

    try {
      final response = await Repository.postApiService(
        EndPoints.getMyQrCode,
        {"provider_id": userData["user_id"] ?? ""},
      );

      final parsed = response is String ? json.decode(response) : response;
      myQrModel = GetMyQrModel.fromJson(parsed);

      if (myQrModel?.status == "valid") {
        setState(() {
          myQrCodeImage = myQrModel?.data?.qrcodeImage;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("QR Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

Future<void> _uploadQrCode() async {
  if (_selectedImage == null) {
    UtilClass.showAlertDialog(
      context: context,
      message: "Please select QR code image",
    );
    return;
  }

  final userId = userData["user_id"];
  if (userId == null || userId.toString().isEmpty) {
    UtilClass.showAlertDialog(
      context: context,
      message: "User ID not found. Please login again.",
    );
    return;
  }

  if (!await UtilClass.checkInternet()) {
    UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
    return;
  }

  setState(() => isUploading = true);
  UtilClass.showProgress(context: context);

  try {
    String fileName = _selectedImage!.path.split('/').last;

    FormData formData = FormData.fromMap({
      "provider_id": userId.toString(), // send as string
      "qrcode_image": await MultipartFile.fromFile(
        _selectedImage!.path,
        filename: fileName,
      ),
    });

    final dio = Dio();
    final response = await dio.post(EndPoints.uploadQrCode, data: formData);

    UtilClass.hideProgress();

    if (response.data["status"] == "valid") {
      await _getQrCodeImage();
   
      UtilClass.showAlertDialog(
        context: context,
        message: "QR Code uploaded successfully",
      );

       
    }
  } catch (e) {
    UtilClass.hideProgress();
     UtilClass.showAlertDialog(
        context: context,
        message: "QR Code uploaded successfully",
      );

  } finally {
    setState(() => isUploading = false);
  }
}

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  /// Bottom sheet for image picker
  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
           
            _buildOption(Icons.image, "Gallery",
                () => _pickImage(ImageSource.gallery)),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green.shade100,
              child: Icon(icon, color: Colors.black)),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  /// QR container helper with responsive size
  Widget _qrContainer({required double size, required Widget child}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final containerSize = screenWidth * 0.6;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFFFFEB3B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text("My QR Code",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      _qrContainer(
                        size: containerSize,
                        child: myQrCodeImage == null || myQrCodeImage!.isEmpty
                            ? const Center(child: Text("No QR Code Found"))
                            : Image.network(
                                "$myQrCodeImage",
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 30),
                      const Text("Upload New QR Code",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showPickerSheet,
                        child: _qrContainer(
                          size: containerSize,
                          child: _selectedImage == null
                              ? const Icon(Icons.upload, size: 50)
                              : Image.file(_selectedImage!, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: containerSize,
                        child: ElevatedButton(
                          onPressed: isUploading ? null : _uploadQrCode,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: isUploading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Upload QR Code"),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
