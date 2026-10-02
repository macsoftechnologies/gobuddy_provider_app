import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/getallCategory_model.dart';
import 'package:gobuddy/models/registartion_model.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../../components/button.dart';
import '../../../components/custom_back_button.dart';
import '../../../utils/config.dart';

import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
 GetAllCategoriesModel?pushintoAllCategoriesModel;
 Categories?mycategories;
Map<int, Map<String, dynamic>> dynamicCategories = {};
 List<Categories> myCategories = [];
List<String> selectedCategoriesList = [];
GetRegistrationModel?pushintoRegModel;

  @override
  void initState() {
    super.initState();
    _getAllCategories();
  }

  Future<void> callLocation() async {
    setState(() => isDetectingLocation = true);
    try {
      Position location = await _determinePosition();
      currentLat = location.latitude;
      currentLong = location.longitude;

      var placemarks = await _getAddressFromLatLng(location);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        String formatted = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

        setState(() {
          address = formatted;
          _addressController.text = formatted;
        });
      }
    } catch (e) {
      if (mounted) {
        UtilClass.showAlertDialog(
          context: context,
          message: "Unable to detect location: ${e.toString()}",
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDetectingLocation = false);
      }
    }
  }

  Future<List<Placemark>> _getAddressFromLatLng(Position position) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return placemarks;
  } catch (e) {
    return Future.error('Error getting address: $e');
  }
}

Future<dynamic> _determinePosition() async {

  try{
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the 
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale 
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
  }
  catch(err){
    print(err);
  return err;
    

  }
}
// callCatDetailsAPI removed — was a dead/unused API call with hardcoded pincode

Future<void> _getAllCategories() async {
  bool internet = await UtilClass.checkInternet();

  if (!internet) {
    UtilClass.showAlertDialog(
      context: context,
      message: "No Internet",
    );
    return;
  }

  try {
    final response =
        await Repository.getApiService(EndPoints.getAllCategories);

    Map<String, dynamic> jsonResponse;

    if (response is String) {
      jsonResponse = json.decode(response);
    } else {
      jsonResponse = Map<String, dynamic>.from(response);
    }

    if (jsonResponse["status"] == "valid") {

      // ✅ CORRECT MODEL PARSING
      pushintoAllCategoriesModel =
          GetAllCategoriesModel.fromJson(jsonResponse);

   setState(() {
  myCategories = pushintoAllCategoriesModel?.categories ?? [];

dynamicCategories.clear();

for (var cat in myCategories) {
  if (cat.category != null &&
      cat.category!.trim().isNotEmpty &&
      cat.id != null) {

    final catName = cat.category!.trim();
    if (catName.toLowerCase() == 'testing') {
      continue;
    }

    int id = int.tryParse(cat.id!) ?? 0;

    dynamicCategories[id] = {
      "name": catName,
      "selected": false,
    };
  }
}
});

    } else {
      UtilClass.showAlertDialog(
        context: context,
        message: jsonResponse["message"] ?? "Failed",
      );
    }

  } catch (e) {
    print("Error: $e");

    UtilClass.showAlertDialog(
      context: context,
      message: "Internal Server Error",
    );
  }
}
  final _formKey = GlobalKey<FormState>();

  bool _submitted = false;

  String name = '';
  String phone = '';
  String altPhone = '';
  String dob = '';
  String email = '';
  String address = '';
  String referralCode = '';
  String? workingCategory;
  String? companyName;
  String? teamCount;
  bool acceptTerms = false;

  File? _profileImage;

  final TextEditingController _techCategoryController = TextEditingController();
  final TextEditingController _workingCategoryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  double? currentLat;
  double? currentLong;
  bool isDetectingLocation = false;



  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }void _showTechnicianCategoryDialog() {
  Map<int, bool> tempSelected = {
    for (var entry in dynamicCategories.entries)
      entry.key: entry.value["selected"] == true,
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          bool hasSelection = tempSelected.values.any((v) => v == true);

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                // 🔹 HEADER
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Select Technician Categories",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...dynamicCategories.entries.map((entry) {
                          int id = entry.key;
                          String name = entry.value["name"];
                          bool selected = tempSelected[id] ?? false;

                          return CheckboxListTile(
                            title: Text(
                              name,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            value: selected,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setModalState(() {
                                tempSelected[id] = value ?? false;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // 🔹 BUTTON (fixed bottom)
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSelection
                            ? Colors.green
                            : Colors.grey.shade300,
                        foregroundColor: hasSelection
                            ? Colors.white
                            : Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: hasSelection
                          ? () {
                              setState(() {
                                for (var entry in tempSelected.entries) {
                                  if (dynamicCategories.containsKey(entry.key)) {
                                    dynamicCategories[entry.key]!["selected"] = entry.value;
                                  }
                                }

                                selectedCategoriesList = dynamicCategories.entries
                                    .where((e) => e.value["selected"] == true)
                                    .map((e) => e.key.toString())
                                    .toList();

                                _techCategoryController.text = dynamicCategories.entries
                                    .where((e) => e.value["selected"] == true)
                                    .map((e) => e.value["name"])
                                    .join(', ');
                              });

                              Navigator.pop(context);
                            }
                          : null,
                      child: const Text(
                        "Proceed",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
 
 
  void _showWorkingCategoryDialog() {
    String? tempCategory = workingCategory;
    TextEditingController companyController = TextEditingController(
      text: companyName ?? "",
    );
    TextEditingController teamCountController = TextEditingController(
      text: teamCount ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isValidSelection = () {
              if (tempCategory == null) return false;
              if (tempCategory == "Organisation") {
                return companyController.text.trim().isNotEmpty &&
                    teamCountController.text.trim().isNotEmpty;
              }
              return true;
            }();

            return Dialog(
              insetPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Working Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    RadioListTile<String>(
                      title: Text("Independent"),
                      value: "Independent",
                      groupValue: tempCategory,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setModalState(() => tempCategory = value);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text("Organisation"),
                      value: "Organisation",
                      groupValue: tempCategory,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setModalState(() => tempCategory = value);
                      },
                    ),
                    if (tempCategory == "Organisation") ...[
                      TextField(
                        controller: companyController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: "Enter Company Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: teamCountController,
                        onChanged: (_) => setModalState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter Team Count",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isValidSelection
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              foregroundColor: isValidSelection
                                  ? Colors.white
                                  : Colors.black54,
                            ),
                            onPressed: isValidSelection
                                ? () {
                                    setState(() {
                                      workingCategory = tempCategory;
                                      _workingCategoryController.text =
                                          workingCategory ?? '';

                                      if (workingCategory == "Organisation") {
                                        companyName = companyController.text
                                            .trim();
                                        teamCount = teamCountController.text
                                            .trim();
                                      } else {
                                        companyName = null;
                                        teamCount = null;
                                      }
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: Text("Proceed"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      errorStyle: TextStyle(color: Colors.red, fontSize: 12),
      labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
      floatingLabelStyle: TextStyle(color: Colors.green, fontSize: 14),
      contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  String? _validateName(String? value) {
    if (!_submitted) return null;
    if (value == null || value.isEmpty) return 'Enter your name';
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return 'Name must contain only alphabets';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (!_submitted) return null;
    if (value == null || value.isEmpty) return 'Enter phone number';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Phone must be 10 digits';
    }
    return null;
  }

  String? _validateAltPhone(String? value) {
    if (!_submitted) return null;
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Alternative phone must be 10 digits';
    }
    return null;
  }

  String? _validateDob(String? value) {
    if (!_submitted) return null;
    if (value == null || value.isEmpty) return 'Enter date of birth';
   
    return null;
  }

  String? _validateEmail(String? value) {
    if (!_submitted) return null;
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!regex.hasMatch(value)) return 'Enter valid email';
    return null;
  }

  void _showSummaryDialog() {
    print("""
Name: $name
Phone: $phone
Alt Phone: $altPhone
DOB: $dob
Email: $email
Tech Category: ${_techCategoryController.text}
Working Category: ${_workingCategoryController.text}
Company Name: $companyName
Team Count: $teamCount
Address: $address
Referral: $referralCode
""");

    Navigator.pushNamed(
      context,
      Config.otpRouteName,
      arguments: {"phone": phone, "fromScreen": "register"},
    );
  }





// Future<void> callProviderRegisterAPI() async {
//   bool internet = await UtilClass.checkInternet();

//   if (!internet) {
//     UtilClass.showAlertDialog(
//       context: context,
//       message: "No Internet",
//     );
//     return;
//   }

// String fullPath = _profileImage!.path;

// String imageName = fullPath.split('/').last;

//  UtilClass.showProgress(context: context);
//   try {
//    final response = await Repository.postApiService(
//   EndPoints.providerRegisterApi,
//   {
//     "name": name,
//     "email": email,
//     "phone_number": phone,
//     "password": "12345",
//     "terms_and_conditions": "testing",
//     "latitude": "17.740678937225038",
//     "longitude": "83.3093623816967",
//     "place_id": "5",
//     "landmark": address,
//     "location": address,
//     "token": "testing",
//     "dob": dob,
//     "address": address,
//     "working_category": workingCategory ?? "",
//     "company_name": companyName ?? "",
//     "team_count": teamCount ?? "",
//     "referral_code": referralCode,
//     "skills": selectedCategoriesList.join(","),

//     "profile": _profileImage != null
//         ? await MultipartFile.fromFile(
//             _profileImage!.path,
//             filename: _profileImage!.path.split('/').last,
//           )
//         : null,
//   },
// );
//     Map<String, dynamic> jsonResponse;
//     if (response is String) {
//       jsonResponse = json.decode(response);
//     } else {
//       jsonResponse = response;
//     }

//     print("Parsed Response: $jsonResponse");

//         UtilClass.hideProgress();

//     if (jsonResponse["status"] == "valid") {
//       setState(() {
//         pushintoRegModel =
//             GetRegistrationModel.fromJson(jsonResponse);
//       });
//       jsonResponse["user_id"] =
//           jsonResponse["user_id"].toString();
//       Preferences.setUserDetails(json.encode(jsonResponse));
//       Navigator.pushNamed(
//         context,
//         Config.otpRouteName,
//         arguments: {
//           "phone": jsonResponse["phone_number"],
//           "user_id": jsonResponse["user_id"],
//           "fromScreen": "register",
//         },
//       );
//     }else{
//       UtilClass.showAlertDialog(context: context, message: jsonResponse["message"]?? "Registration Failed");
//     }
//   } catch (e) {
//     print("Error: $e");

//     UtilClass.showAlertDialog(
//       context: context,
//       message: "Internal Server Error",
//     );
//   }
// }
  


  Future<void> callProviderRegisterAPI() async {
  bool internet = await UtilClass.checkInternet();

  if (!internet) {
    UtilClass.showAlertDialog(
      context: context,
      message: "No Internet",
    );
    return;
  }

  UtilClass.showProgress(context: context);

  try {
    final response = await Repository.postApiService(
      EndPoints.providerRegisterApi,
      {
        "name": name,
        "email": email,
        "phone_number": phone,
        "password": "OTP_${DateTime.now().millisecondsSinceEpoch}",
        "terms_and_conditions": "accepted",
        "latitude": currentLat?.toString() ?? "17.740678937225038",
        "longitude": currentLong?.toString() ?? "83.3093623816967",
        "place_id": "",
        "landmark": address,
        "location": address,
        "token": Preferences.getFcmToken() ?? "testing",
        "dob": dob,
        "address": address,
        "working_category": workingCategory ?? "",
        "company_name": companyName ?? "",
        "team_count": teamCount ?? "",
        "referral_code": referralCode,
        "skills": selectedCategoriesList.join(","),
        "profile": _profileImage != null
            ? await MultipartFile.fromFile(
                _profileImage!.path,
                filename: _profileImage!.path.split('/').last,
              )
            : null,
      },
    );

    Map<String, dynamic> jsonResponse;

    if (response is String) {
      jsonResponse = json.decode(response);
    } else {
      jsonResponse = response;
    }

    print("Parsed Response: $jsonResponse");

    if (jsonResponse["status"] == "valid") {
      setState(() {
        pushintoRegModel =
            GetRegistrationModel.fromJson(jsonResponse);
      });

      jsonResponse["user_id"] =
          jsonResponse["user_id"].toString();

      Preferences.setUserDetails(json.encode(jsonResponse));

      Navigator.pushNamed(
        context,
        Config.otpRouteName,
        arguments: {
          "phone": jsonResponse["phone_number"],
          "user_id": jsonResponse["user_id"],
          "fromScreen": "register",
        },
      );
    } else {
      UtilClass.showAlertDialog(
        context: context,
        message: jsonResponse["message"] ?? "Registration Failed",
      );
    }
  } catch (e) {
    print("Error: $e");

    UtilClass.showAlertDialog(
      context: context,
      message: "Internal Server Error",
    );
  } finally {
    // ✅ ALWAYS runs (success / error / exception)
    UtilClass.hideProgress();
  }
}
  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            deviceWidth * 0.04,
            0,
            deviceWidth * 0.04,
            deviceWidth * 0.04,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: deviceWidth * 0.14,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? Icon(Icons.person, size: deviceWidth * 0.14)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: PopupMenuButton<ImageSource>(
                          icon: Icon(Icons.camera_alt, color: Colors.blue),
                          onSelected: _pickImage,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: ImageSource.camera,
                              child: Text("Take Photo"),
                            ),
                            PopupMenuItem(
                              value: ImageSource.gallery,
                              child: Text("Choose from Gallery"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                TextFormField(
                  decoration: _inputDecoration('Name'),
                  onChanged: (v) => setState(() => name = v),
                  validator: _validateName,
                ),
                SizedBox(height: 15),

                TextFormField(
                  decoration: _inputDecoration('Phone Number'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (v) => setState(() => phone = v),
                  validator: _validatePhone,
                ),
                SizedBox(height: 15),

                TextFormField(
                  decoration: _inputDecoration('Alternative Phone Number'),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (v) => setState(() => altPhone = v),
                  validator: _validateAltPhone,
                ),
                SizedBox(height: 15),

                TextFormField(
                  decoration: _inputDecoration('Date of Birth (DD/MM/YYYY)'),
                  keyboardType: TextInputType.text,
                  onChanged: (v) => setState(() => dob = v),
                  validator: _validateDob,
                ),
                SizedBox(height: 15),

                TextFormField(
                  decoration: _inputDecoration('Email (Optional)'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => setState(() => email = v),
                  validator: _validateEmail,
                ),
                SizedBox(height: 15),

                GestureDetector(
                  onTap: _showTechnicianCategoryDialog,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _techCategoryController,
                      maxLines: null,
                      minLines: 1,
                      decoration: _inputDecoration(
                        'Technician Category',
                      ).copyWith(suffixIcon: Icon(Icons.arrow_drop_down)),
                      validator: (v) {
                        if (!_submitted) return null;
                        return v == null || v.isEmpty
                            ? 'Select a category'
                            : null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),

                GestureDetector(
                  onTap: _showWorkingCategoryDialog,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _workingCategoryController,
                      decoration: _inputDecoration(
                        'Working Category',
                      ).copyWith(suffixIcon: Icon(Icons.arrow_drop_down)),
                      validator: (v) {
                        if (!_submitted) return null;
                        return v == null || v.isEmpty
                            ? 'Select working category'
                            : null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),

                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('Address').copyWith(
                    suffixIcon: isDetectingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.green),
                            tooltip: "Use Current Location",
                            onPressed: () {
                              callLocation();
                            },
                          ),
                  ),
                  onChanged: (v) => address = v,
                  validator: (v) {
                    if (!_submitted) return null;
                    return v == null || v.isEmpty ? 'Enter address' : null;
                  },
                ),
                SizedBox(height: 15),

                TextFormField(
                  decoration: _inputDecoration('Referral Code (Optional)'),
                  onChanged: (v) => referralCode = v,
                ),
                SizedBox(height: 15),

                Row(
                  children: [
                    Checkbox(
                      value: acceptTerms,
                      onChanged: (val) {
                        setState(() => acceptTerms = val ?? false);
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Accept Terms and Conditions",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                if (_submitted && !acceptTerms)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "You must accept terms",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                SizedBox(height: 20),

                GradientButton(
                  onPressed: () {
                    setState(() => _submitted = true);
                    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                      if (!acceptTerms) {
                        UtilClass.showAlertDialog(
                          context: context,
                          message: "Please accept the Terms and Conditions to proceed.",
                        );
                        return;
                      }
                      callProviderRegisterAPI();
                    } else {
                      UtilClass.showAlertDialog(
                        context: context,
                        message: "Please fill in all required mandatory fields correctly.",
                      );
                    }
                  },
                  child: Text(
                    "Register",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
