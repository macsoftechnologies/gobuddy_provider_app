import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/update_p_model.dart';
import 'package:gobuddy/models/update_profile_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../components/button.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  _ViewProfilePageState createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  dynamic userData = {};

  File? _profileImage;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  GetProfileModel? pushintopmodel;
  Profile? myprofile;

  String _getImageUrl(String? path) {
    return UtilClass.formatProfileImageUrl(path);
  }

  @override
  void initState() {
    super.initState();

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    _getProfileDetails();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // ✅ UPDATE PROFILE
  Future<void> _updateProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Name cannot be empty. Please enter your name.",
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(name)) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Name must contain only alphabets.",
      );
      return;
    }

    final email = emailController.text.trim();
    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Please enter a valid email address.",
        );
        return;
      }
    }

    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(
          context: context, message: "No Internet Connection");
      return;
    }

    UtilClass.showProgress(context: context);

    Map<String, dynamic> data = {
      "name": name,
      "email": email,
      "terms_and_conditions": "profile",
      "latitude": myprofile?.latitude ?? userData["latitude"] ?? "17.7406789",
      "longitude": myprofile?.longitude ?? userData["longitude"] ?? "83.3093623",
      "place_id": myprofile?.placeId ?? userData["place_id"] ?? "",
      "landmark": addressController.text.trim(),
      "location": addressController.text.trim(),
      "dob": dobController.text.trim(),
      "user_id": userData["user_id"] ?? "",
    };

    if (_profileImage != null) {
      data["profile"] = await MultipartFile.fromFile(
        _profileImage!.path,
        filename: _profileImage!.path.split('/').last,
      );
    }

    final response =
        await Repository.postApiService(EndPoints.updateProfile, data);

    UtilClass.hideProgress();

    try {
      final parsed = response is String ? json.decode(response) : response;

      if (parsed["status"] == "valid") {
        UtilClass.showAlertDialog(
          context: context,
          message: "Profile updated successfully",
        );

        _getProfileDetails(); // 🔥 refresh
      } else {
        UtilClass.showAlertDialog(
          context: context,
          message: parsed["message"],
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // ✅ GET PROFILE
  Future<void> _getProfileDetails() async {
    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(
          context: context, message: "No Internet Connection");
      return;
    }

    try {
      final response = await Repository.postApiService(
          EndPoints.getProfileDetails,
          {"user_id": userData["user_id"] ?? ""});

      Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : response;

      if (jsonResponse["status"] == "valid") {
        pushintopmodel = GetProfileModel.fromJson(jsonResponse);

        setState(() {
          myprofile = pushintopmodel!.profile;

          nameController.text = myprofile?.name ?? "";
          phoneController.text = myprofile?.phoneNumber ?? "";
          emailController.text = myprofile?.email ?? "";
          dobController.text = myprofile?.dob ?? "";
          addressController.text = myprofile?.address ?? "";
        });
      } else {
        UtilClass.showAlertDialog(
            context: context,
            message:
                jsonResponse["message"] ?? "Failed to fetch profile details");
      }
    } catch (e) {
      UtilClass.showAlertDialog(
          context: context, message: "Internal Server Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("View Profile"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFC8BB47), Color(0xFF25AC2C)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: deviceWidth * 0.14,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: _profileImage != null
                        ? Image.file(
                            _profileImage!,
                            width: deviceWidth * 0.28,
                            height: deviceWidth * 0.28,
                            fit: BoxFit.cover,
                          )
                        : ((myprofile?.profile != null &&
                                myprofile!.profile!.trim().isNotEmpty)
                            ? Image.network(
                                _getImageUrl(myprofile!.profile),
                                width: deviceWidth * 0.28,
                                height: deviceWidth * 0.28,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.person,
                                  size: deviceWidth * 0.14,
                                  color: Colors.grey,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: deviceWidth * 0.14,
                                color: Colors.grey,
                              )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: PopupMenuButton<ImageSource>(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onSelected: _pickImage,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ImageSource.camera,
                        child: Text("Take Photo"),
                      ),
                      const PopupMenuItem(
                        value: ImageSource.gallery,
                        child: Text("Choose from Gallery"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildTextField("Name", false, nameController),
            _buildTextField("Phone Number", true, phoneController),
            _buildTextField("Email", false, emailController),
            _buildTextField("Date of Birth", false, dobController),
            _buildTextField("Address", false, addressController),

            const SizedBox(height: 20),

            GradientButton(
              onPressed: _updateProfile,
              child: Text(
                'Update Profile',
                style: TextStyle(
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

  Widget _buildTextField(
      String label, bool readOnly, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    dobController.dispose();
    super.dispose();
  }
}