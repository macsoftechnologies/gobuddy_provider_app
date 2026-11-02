import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/update_p_model.dart';
import 'package:gobuddy/models/update_profile_model.dart';
import 'package:gobuddy/pages/authentication/login/login_screen.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
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
      try {
        userData = json.decode(userDataValue);
        // Pre-fill controllers immediately from cached data so nothing appears blank
        nameController.text = (userData["name"] ?? Preferences.getName() ?? "").toString();
        phoneController.text = (userData["phone_number"] ?? userData["phone"] ?? "").toString();
        emailController.text = (userData["email"] ?? "").toString();
        addressController.text = (userData["address"] ?? userData["location"] ?? "").toString();
        final rawDob = (userData["dob"] ?? "").toString().trim();
        if (rawDob.isNotEmpty && rawDob != "0000-00-00") {
          try {
            final parsed = DateTime.tryParse(rawDob);
            if (parsed != null) {
              dobController.text =
                  "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
            } else {
              dobController.text = rawDob;
            }
          } catch (_) {
            dobController.text = rawDob;
          }
        }
      } catch (_) {}
    }

    _getProfileDetails();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
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

    final String userId = (myprofile?.id ??
            userData["user_id"] ??
            userData["id"] ??
            Preferences.getUserID() ??
            "")
        .toString()
        .trim();

    if (userId.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "User ID not found. Please log in again.",
      );
      return;
    }

    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(
          context: context, message: "No Internet Connection");
      return;
    }

    UtilClass.showProgress(context: context);

    final String updatedAddress = addressController.text.trim();

    Map<String, dynamic> data = {
      "name": name,
      "email": email,
      "address": updatedAddress,
      "landmark": updatedAddress,
      "location": updatedAddress,
      "terms_and_conditions": "profile",
      "latitude": myprofile?.latitude ?? userData["latitude"] ?? "17.7406789",
      "longitude": myprofile?.longitude ?? userData["longitude"] ?? "83.3093623",
      "place_id": myprofile?.placeId ?? userData["place_id"] ?? "",
      "dob": dobController.text.trim(),
      "user_id": userId,
    };

    if (_profileImage != null) {
      data["profile"] = await MultipartFile.fromFile(
        _profileImage!.path,
        filename: _profileImage!.path.split(RegExp(r'[/\\]')).last,
      );
    }

    final response =
        await Repository.postApiService(EndPoints.updateProfile, data);

    UtilClass.hideProgress();

    try {
      final parsed = response is String ? json.decode(response) : response;

      if (parsed["status"] == "valid" || parsed["status"] == true) {
        // Sync updated details directly into local preferences cache
        try {
          final userMap = Map<String, dynamic>.from(userData ?? {});
          userMap["name"] = name;
          userMap["email"] = email;
          userMap["address"] = updatedAddress;
          userMap["location"] = updatedAddress;
          userMap["dob"] = dobController.text.trim();
          userMap["user_id"] = userId;
          Preferences.setUserDetails(json.encode(userMap));
          Preferences.setName(name);
          userData = userMap;
        } catch (_) {}

        UtilClass.showAlertDialog(
          context: context,
          message: "Profile updated successfully",
        );

        _getProfileDetails(); // 🔥 refresh
      } else {
        UtilClass.showAlertDialog(
          context: context,
          message: parsed["message"] ?? "Failed to update profile",
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

    final String userId = (myprofile?.id ??
            userData["user_id"] ??
            userData["id"] ??
            Preferences.getUserID() ??
            "")
        .toString()
        .trim();

    if (userId.isEmpty) return;

    try {
      final response = await Repository.postApiService(
          EndPoints.getProfileDetails,
          {"user_id": userId});

      Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : response;

      if (jsonResponse["status"] == "valid") {
        pushintopmodel = GetProfileModel.fromJson(jsonResponse);

        setState(() {
          myprofile = pushintopmodel!.profile;

          if (myprofile?.name != null && myprofile!.name!.isNotEmpty) {
            nameController.text = myprofile!.name!;
          }
          if (myprofile?.phoneNumber != null && myprofile!.phoneNumber!.isNotEmpty) {
            phoneController.text = myprofile!.phoneNumber!;
          }
          if (myprofile?.email != null) {
            emailController.text = myprofile!.email!;
          }
          final rawDob = (myprofile?.dob ?? "").trim();
          if (rawDob.isNotEmpty && rawDob != "0000-00-00") {
            try {
              final parsed = DateTime.tryParse(rawDob);
              if (parsed != null) {
                dobController.text =
                    "${parsed.day.toString().padLeft(2, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.year}";
              } else {
                dobController.text = rawDob;
              }
            } catch (_) {
              dobController.text = rawDob;
            }
          }
          if (myprofile?.address != null && myprofile!.address!.isNotEmpty) {
            addressController.text = myprofile!.address!;
          }
        });

        // Sync fresh profile into local Preferences
        try {
          final userMap = Map<String, dynamic>.from(userData ?? {});
          userMap["user_id"] = userId;
          if (myprofile?.name != null && myprofile!.name!.isNotEmpty) {
            userMap["name"] = myprofile!.name;
            Preferences.setName(myprofile!.name!);
          }
          if (myprofile?.email != null) userMap["email"] = myprofile!.email;
          if (myprofile?.phoneNumber != null) userMap["phone_number"] = myprofile!.phoneNumber;
          if (myprofile?.address != null) userMap["address"] = myprofile!.address;
          if (myprofile?.profile != null) userMap["profile"] = myprofile!.profile;
          if (myprofile?.dob != null) userMap["dob"] = myprofile!.dob;
          if (myprofile?.skills != null) userMap["skills"] = myprofile!.skills;
          Preferences.setUserDetails(json.encode(userMap));
          userData = userMap;
        } catch (_) {}
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

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 20));
    final currentText = dobController.text.trim();
    if (currentText.isNotEmpty) {
      final parts = currentText.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          initial = DateTime.tryParse(currentText) ?? initial;
        } else if (parts[2].length == 4) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            initial = DateTime(y, m, d);
          }
        }
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      setState(() {
        dobController.text = formatted;
      });
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
    final String userId = (myprofile?.id ??
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
                        : (() {
                            final String img = (myprofile?.profile != null &&
                                    myprofile!.profile!.trim().isNotEmpty)
                                ? myprofile!.profile!.trim()
                                : (userData["profile"] ?? userData["profile_image"] ?? "")
                                    .toString()
                                    .trim();
                            if (img.isNotEmpty) {
                              return Image.network(
                                _getImageUrl(img),
                                width: deviceWidth * 0.28,
                                height: deviceWidth * 0.28,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.person,
                                  size: deviceWidth * 0.14,
                                  color: Colors.grey,
                                ),
                              );
                            }
                            return Icon(
                              Icons.person,
                              size: deviceWidth * 0.14,
                              color: Colors.grey,
                            );
                          })(),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: dobController,
                readOnly: true,
                onTap: _selectDateOfBirth,
                decoration: InputDecoration(
                  labelText: "Date of Birth",
                  hintText: "DD-MM-YYYY",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF4CAF50)),
                    onPressed: _selectDateOfBirth,
                  ),
                ),
              ),
            ),
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

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: _showDeleteAccountDialog,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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