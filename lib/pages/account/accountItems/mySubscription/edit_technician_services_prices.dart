import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../../../utils/config.dart';

class EditTechnicianServicesPrices extends StatefulWidget {
  final dynamic categoryName;
  final dynamic planName;
  final String planType;

  const EditTechnicianServicesPrices({
    super.key,
    required this.categoryName,
     required this.planName,
    required this.planType,
  });

  @override
  State<EditTechnicianServicesPrices> createState() =>
      _EdityTechnicianServicesPricesState();
}

typedef MenuEntry = DropdownMenuEntry<String>;
const List<String> list = ['%', '₹'];

class _EdityTechnicianServicesPricesState extends State<EditTechnicianServicesPrices> {
  double deviceHeight = 0;
  double deviceWidth = 0;
  int subCatIndex = 0;
  dynamic subCat = "";
  bool isPackageSelected = false; // for Add button state
  int? selectedPackage; // selected package index

  // Job Packages JSON
  final List<Map<String, dynamic>> jobPackages = [
    {"jobs": 20, "price": 999},
    {"jobs": 40, "price": 1499},
    {"jobs": 60, "price": 2399},
  ];

  static final List<MenuEntry> menuEntries = UnmodifiableListView<MenuEntry>(
    list.map<MenuEntry>((String name) => MenuEntry(value: name, label: name)),
  );
  String dropdownValue = list.first;

  List<dynamic> subcatDetails = [];
  List<dynamic> serviceDetails = [];
  List<dynamic> packages = [];

  dynamic userData = {};

  dynamic selectedPack = {};

  void callAddsubscriptionAPI(dynamic data) async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiServiceWithJson(
        EndPoints.addprovSubscriptionApi,
        data,
      ).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            UtilClass.showAlertDialog(
              // ignore: use_build_context_synchronously
              context: context,
              message: parsed["message"],
            );

            Navigator.pushNamed(context, Config.planSummaryRouteName);
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

  void callgetPlansAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.packagesApi, {
        "sub_category_id": "27",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            packages = parsed["package"];

            setState(() {
              selectedPack = parsed["package"][0];
            });

            setState(() {
              packages = parsed["package"];
            });
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

  void callgetServicesAPI(int id) async {
    setState(() {
      serviceDetails = subcatDetails[id]["services"];
    });

    // var internet = await UtilClass.checkInternet();
    // if (internet) {
    //   // ignore: use_build_context_synchronously
    //   UtilClass.showProgress(context: context);
    //   await Repository.postApiService(EndPoints.servicesApi, {
    //     "sub_category_id": id,
    //   }).then((value) async {
    //     UtilClass.hideProgress();
    //     dynamic parsed = {};
    //     try {
    //       parsed = await json.decode(value);
    //       if (parsed["status"] == "valid") {
    //         serviceDetails = parsed["services"];

    //         setState(() {
    //           serviceDetails = parsed["services"];
    //         });
    //       } else {
    //         // ignore: use_build_context_synchronously
    //         UtilClass.showAlertDialog(
    //           // ignore: use_build_context_synchronously
    //           context: context,
    //           message: parsed["message"],
    //         );
    //       }
    //     } catch (e) {
    //       print(e);
    //     }
    //     print(parsed["message"]);
    //   });
    // } else {
    //   // ignore: use_build_context_synchronously
    //   UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    // }
  }

  void callgetSubCatAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.catsubCat, {
        "category_id": widget.categoryName["categoryName"]["id"]! ?? "" ?? "1",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            // subcatDetails = parsed["sub_category"];
            for (int i = 0; i < parsed["sub_category"].length; i++) {
              var services = parsed["sub_category"][i]["services"];
              for (int j = 0; j < parsed["sub_category"].length; j++) {
                try {
                  services[j]["tprice"] = "";
                  services[j]["tdiscount"] = "";
                  services[j]["ttotal"] = "0.00";
                  services[j]["acontroller"] = TextEditingController(text: '');
                  services[j]["dcontroller"] = TextEditingController(text: '');
                   services[j]["menuselect"] = list.first;
                   services[j]["menuselectVal"] = "%";
                } catch (err) {}

                // Set the boolean value
              }
              parsed["sub_category"][i]["services"] = services;
            }

            setState(() {
              subcatDetails = parsed["sub_category"];
            });

            // callgetServicesAPI(subcatDetails[0]["id"]);

            // serviceDetails = subcatDetails[0]["services"];
            subCat = subcatDetails[0]["id"];
            setState(() {
              serviceDetails = subcatDetails[0]["services"];
            });
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

  @override
  void initState() {
    super.initState();

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    callgetSubCatAPI();

    var data  = widget.planName;

    print(data);

     setState(() {
              selectedPack = widget.planName["packages"][0];
            });

            setState(() {
              packages = widget.planName["packages"]??[];
            });
    // callgetPlansAPI();
  }

  // Sample JSON data for service cards
  final List<Map<String, dynamic>> serviceList = [
    {"title": "Dry Servicing a Split Ac", "image": "assets/images/ac.png"},
    {"title": "AC Installation", "image": "assets/images/ac.png"},
    {"title": "Jet servicing of split AC", "image": "assets/images/ac.png"},
  ];

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header Section with Image
                SizedBox(
                  height: deviceHeight * 0.28,
                  width: deviceWidth,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          UtilClass.formatImageUrl(widget.categoryName["categoryName"]["image"]),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, size: 50)),
                        ),
                      ),
                      Container(color: Colors.black.withOpacity(0.2)),
                      Positioned(
                        left: 16,
                        top: 16,
                        right:
                        16, // Added right constraint to ensure proper spacing
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: _buildBackButton(),
                            ),
                            SizedBox(width: deviceWidth * 0.03),
                            //const SizedBox(width: 16), // Add spacing between icon and text
                            Expanded(
                              child: Text(
                                widget.categoryName["categoryName"]["category"]! ??
                                    "",
                                style: TextStyle(
                                  fontSize: deviceWidth * 0.06,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines:
                                2, // Allow text to wrap to second line if needed
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: deviceWidth * 0.05,
                      vertical: deviceHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.planType,
                          style: TextStyle(
                            fontSize: deviceWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: deviceHeight * 0.015),

                        //Plan Price Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showJobPackageBottomSheet();
                              },
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      selectedPack["amount"] ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedPack["jobs"] ?? "",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // _showJobPackageBottomSheet();
                                List<dynamic> servicesData = [];
                                List<dynamic> copiedList = [...subcatDetails];
                                for (int i = 0; i < copiedList.length; i++) {
                                  var services = copiedList[i]["services"];
                                  for (int j = 0; j < services.length; j++) {
                                    try {
                                      var amount =
                                          services[j]["acontroller"].text;
                                      var discount =
                                          services[j]["dcontroller"].text;

                                      if (amount.length > 0) {
                                        servicesData.add({
                                          "service_id": services[j]["sid"],
                                          "price": amount,
                                          "discount": discount,
                                        });
                                      }
                                      // services[j]["tprice"] = "";
                                      // services[j]["tdiscount"] = "";
                                      // services[j]["ttotal"] = "0.00";
                                      // services[j]["acontroller"] =
                                      //     TextEditingController(text: '');
                                      // services[j]["dcontroller"] =
                                      //     TextEditingController(text: '');
                                    } catch (err) {}

                                    // Set the boolean value
                                  }
                                }

                                print(servicesData);

                                if (servicesData.length > 0) {
                                  var data = {
                                    "provider_id": userData["user_id"],
                                    "category_id": widget
                                        .categoryName["categoryName"]["id"],
                                    "sub_category_id": subCat,
                                    "subscription": widget.planType,
                                    "jobs": selectedPack["jobs"],
                                    "package": selectedPack["amount"],
                                    "services": servicesData,
                                  };
                                  print(data);

                                  callAddsubscriptionAPI(data);
                                } else {
                                  UtilClass.showAlertDialog(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    message:
                                        "please add any one of the service",
                                  );
                                }

                                print("cesData");
                              },
                              child: isPackageSelected
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Added',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: const Text(
                                        "Add",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        SizedBox(height: deviceHeight * 0.02),

                        // AC Type Selection
                        SizedBox(
                          height: deviceHeight * 0.18, // Set a fixed height for the horizontal list
                          child: ListView.builder(

                            scrollDirection: Axis
                                .horizontal, // Important: Set scroll direction to horizontal
                            itemCount: subcatDetails
                                .length, // Number of items in the list
                            itemBuilder: (context, index) {
                              final bool isSelected = subCatIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  subCat = subcatDetails[index]["id"];
                                  subCatIndex = index;
                                  callgetServicesAPI(index);
                                },
                                child: Container(
                                  width: deviceHeight * 0.14,
                                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? Colors.green : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          UtilClass.formatImageUrl(subcatDetails[index]["sub_image"]?.toString()),
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image, size: 50),
                                          height: deviceHeight * 0.10,
                                          width: deviceHeight * 0.10,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        subcatDetails[index]["sub_category"],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? Colors.green : Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),


                        SizedBox(height: deviceHeight * 0.02),

                        const Text(
                          "Enter your service price and discount",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: deviceHeight * 0.01),

                        // Dynamic Cards from JSON
                        Column(
                          children: serviceDetails.asMap().entries.map((entry) {
                            int index = entry.key;
                            dynamic item = entry.value;
                            return serviceCard(
                              item["title"],
                              item["service_image"],
                              index,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ---------------- Bottom Card ----------------
            if (isPackageSelected)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row with Grey Border
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Side (Title & Plan)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.categoryName["categoryName"]["category"]! ??
                                      "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${widget.planType} (20 Jobs)",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            // Right Side (Delete + Price)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPackageSelected = false;
                                    });
                                  },
                                ),
                                const Text(
                                  "₹999",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 1 Plan Added
                      Row(
                        children: const [
                          Text(
                            "1 Plan Added",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Add More",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  Config.planSummaryRouteName,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "View Summary",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  /// Back Button
  Widget _buildBackButton() {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.arrow_back_ios_new,
        color: Colors.black,
        size: 18,
      ),
    );
  }
  Widget serviceCard(String title, String imageUrl, int? index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              UtilClass.formatImageUrl(imageUrl),
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50),
              height: deviceHeight * 0.1,
              width: deviceWidth * 0.2,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: deviceWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:
                        subcatDetails[subCatIndex]["services"][index]["acontroller"],
                        onChanged: (value) {
                          var data =
                          subcatDetails[subCatIndex]["services"][index];

                          subcatDetails[subCatIndex]["services"][index]["acontroller"]
                              .text =
                              value;

                          double? totalvalue = 0;
                          try {
                            var amount = int.parse(
                              subcatDetails[subCatIndex]["services"][index]["acontroller"]
                                  .text,
                            );
                            var discount = 0;
                            try {
                              discount = int.parse(
                                subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                    .text,
                              );
                            } catch (err) {
                              discount = 0;
                            }

                            var types  = subcatDetails[subCatIndex]["services"][index]["menuselectVal"];
                            totalvalue = (types == "%" ? (amount - (amount * discount) / 100): (amount -  discount).toDouble()) ;
                          } catch (err) {
                            totalvalue = 0;
                          }
                          setState(() {
                            subcatDetails[subCatIndex]["services"][index]["ttotal"] =
                                totalvalue.toString();

                            // You can also update other properties of the object here
                          });

                          // subcatDetails[subCatIndex]["services"][index]["tprice"] = value;
                          // Perform actions with the updated 'value'
                          print('Text changed: $value');
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ), // Example: Allows digits and up to 2 decimal places
                        ],

                        decoration: InputDecoration(
                          hintText: "price",
                          prefixText: "₹ ",
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Dropdown Menu - now using Expanded to match price row width
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        child: DropdownMenu<String>(
                          inputDecorationTheme: const InputDecorationTheme(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            constraints: BoxConstraints.tightFor(height: 48),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                width: 1.2,
                                color: Colors.grey,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                          ),
                          initialSelection: subcatDetails[subCatIndex]["services"][index]["menuselect"],
                          onSelected: (String? value) {
                            // This is called when the user selects an item.
                            setState(() {
                              subcatDetails[subCatIndex]["services"][index]["menuselectVal"] = value;
                              dropdownValue = value!;
                            });

                            var data =
                            subcatDetails[subCatIndex]["services"][index];

                            // subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                            //         .text =
                            //     value;

                            double totalvalue = 0;
                            try {
                              var amount = int.parse(
                                subcatDetails[subCatIndex]["services"][index]["acontroller"]
                                    .text,
                              );
                              var discount = 0;
                              try {
                                discount = int.parse(
                                  subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                      .text,
                                );
                              } catch (err) {
                                discount = 0;
                              }

                              var types  = subcatDetails[subCatIndex]["services"][index]["menuselectVal"];
                              totalvalue = (types == "%" ? (amount - (amount * discount) / 100): (amount -  discount).toDouble()) ;
                            } catch (err) {
                              totalvalue = 0;
                            }

                            setState(() {
                              subcatDetails[subCatIndex]["services"][index]["ttotal"] =
                                  totalvalue.toString();

                              // You can also update other properties of the object here
                            });
                          },
                          dropdownMenuEntries: menuEntries,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Discount TextField - now using Expanded to match price row width
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 48,
                        child: TextField(
                          controller:
                          subcatDetails[subCatIndex]["services"][index]["dcontroller"],
                          onChanged: (value) {
                            var data =
                            subcatDetails[subCatIndex]["services"][index];

                            subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                .text =
                                value;

                            double totalvalue = 0;
                            try {
                              var amount = int.parse(
                                subcatDetails[subCatIndex]["services"][index]["acontroller"]
                                    .text,
                              );
                              var discount = 0;
                              try {
                                discount = int.parse(
                                  subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                      .text,
                                );
                              } catch (err) {
                                discount = 0;
                              }

                              var types  = subcatDetails[subCatIndex]["services"][index]["menuselectVal"];
                              totalvalue = (types == "%" ? (amount - (amount * discount) / 100): (amount -  discount).toDouble()) ;
                            } catch (err) {
                              totalvalue = 0;
                            }

                            setState(() {
                              subcatDetails[subCatIndex]["services"][index]["ttotal"] =
                                  totalvalue.toString();

                              // You can also update other properties of the object here
                            });

                            // subcatDetails[subCatIndex]["services"][index]["tprice"] = value;
                            // Perform actions with the updated 'value'
                            print('Text changed: $value');
                          },
                          decoration: InputDecoration(
                            hintText: "Discount",
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(
                  // ignore: prefer_interpolation_to_compose_strings
                  "Total  ₹ " +
                      subcatDetails[subCatIndex]["services"][index]["ttotal"],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJobPackageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Jobs Package",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(packages.length, (index) {
                    return Column(
                      children: [
                        RadioListTile<int>(
                          value: index,
                          groupValue: selectedPackage,
                          onChanged: (dynamic val) {
                            setModalState(() {
                              selectedPackage = val;
                            });
                            setState(() {
                              selectedPack = packages[val];
                            });
                          },
                          title: Text(
                            "${packages[index]["jobs"]} Jobs / ₹ ${packages[index]["amount"]}",
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedPackage != null
                        ? () {
                            // setState(() {
                            //   isPackageSelected = true;
                            // });

                            //                   setState(() {
                            //   selectedPack = selectedPackage;
                            // });
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedPackage != null
                          ? Colors.green
                          : Colors.grey.shade300,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: selectedPackage != null
                            ? Colors.white
                            : Colors.black54,
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
}
