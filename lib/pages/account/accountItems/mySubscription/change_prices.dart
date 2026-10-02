import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/pages/account/accountItems/mySubscription/update_plan_summary.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';

import '../../../../components/custom_back_button.dart';

class ChangePricesScreen extends StatefulWidget {
  final dynamic subscriptiondetails;
  const ChangePricesScreen({super.key, required this.subscriptiondetails});

  @override
  State<ChangePricesScreen> createState() => _ChangePricesScreenState();
}

typedef MenuEntry = DropdownMenuEntry<String>;
const List<String> list = ['%', '₹'];

class _ChangePricesScreenState extends State<ChangePricesScreen> {
  // Sample JSON data
  final String jsonData = '''
  {
    "subscription": {
      "title": "AC Technician",
      "plan": "Basic Plan",
      "jobs": 20,
      "price": 999,
      "categories": [
        {
          "name": "Split AC",
          "image": "assets/ac.png",
          "services": [
            {
              "name": "Dry Servicing a Split Ac",
              "image": "assets/images/DryAcCleaning.jpg",
              "price": 499,
              "discountPercent": 20,
              "discountAmount": 0
            },
            {
              "name": "AC Installation",
              "image": "assets/images/ACInstallation.jpg",
              "price": 1299,
              "discountPercent": 0,
              "discountAmount": 0
            },
            {
              "name": "Jet servicing of split AC",
              "image":"assets/images/ACJetServicing.jpg",
              "price": 799,
              "discountPercent": 0,
              "discountAmount": 100
            }
          ]
        },
        {
          "name": "Cassette AC",
          "image": "assets/images/AcUninstall.png",
          "services": []
        }
      ]
    }
  }
  ''';

  late Map<String, dynamic> subscriptionData = [] as Map<String, dynamic>;
  int selectedCategory = 0;
  bool _showProceedButton = true;

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
  List<dynamic> addonsData = [];

  dynamic userData = {};

  dynamic selectedPack = {};

  void callUpdatesubscriptionAPI(dynamic data) async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiServiceWithJson(
        EndPoints.upadteprovSubscriptionApi,
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
        "category_id": widget.subscriptiondetails["category_id"],
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);
          if (parsed["status"] == "valid") {
            // subcatDetails = parsed["sub_category"];
            dynamic existServices = widget.subscriptiondetails["services"];
            for (int i = 0; i < parsed["sub_category"].length; i++) {
              var services = parsed["sub_category"][i]["services"];
              for (int j = 0; j < services.length; j++) {
                try {
                  dynamic selItem = {};

                  existServices.forEach(
                    (var item) => {
                      if (item["service_id"] == services[j]["id"])
                        {selItem = item},
                    },
                  );

                  if (selItem.length > 0) {
                    try {
                      var serverPrice = selItem["price"];
                      var serverDiscount = selItem["discount"];
                      var typemode = selItem["type"] == "percentage"
                          ? "%"
                          : "₹";

                      services[j]["tprice"] = serverPrice;
                      services[j]["tdiscount"] = serverDiscount;
                      services[j]["subscription_service_id"] =
                          selItem["subscription_service_id"] ?? "";

                      double totalvalue = 0;
                      int amount = 0;
                      int discount = 0;
                      try {
                        amount = double.parse(serverPrice).toInt();
                      } catch (err) {}
                      try {
                        discount = double.parse(serverDiscount).toInt();
                      } catch (err) {}

                      totalvalue = typemode == "%"
                          ? (amount - (amount * discount) / 100)
                          : (amount - discount).toDouble();

                      services[j]["ttotal"] = totalvalue.toString();
                      services[j]["acontroller"] = TextEditingController(
                        text: selItem["price"],
                      );
                      services[j]["dcontroller"] = TextEditingController(
                        text: selItem["discount"],
                      );
                      services[j]["menuselect"] = typemode;
                      services[j]["menuselectVal"] = typemode;
                    } catch (err) {}
                  } else {
                    try {
                      services[j]["tprice"] = "";
                      services[j]["tdiscount"] = "";
                      services[j]["ttotal"] = "10.00";
                      services[j]["acontroller"] = TextEditingController(
                        text: '',
                      );
                      services[j]["dcontroller"] = TextEditingController(
                        text: '',
                      );
                      services[j]["menuselect"] = list.first;
                      services[j]["menuselectVal"] = "%";
                    } catch (err) {}
                  }
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

  void callAddonsAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.catAddons, {
        "category_id": widget.subscriptiondetails["category_id"]! ?? "" ?? "1",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = await json.decode(value);

          dynamic existOrders = widget.subscriptiondetails["addons"];

          if (parsed["status"] == "valid") {
            for (int i = 0; i < parsed["addons"].length; i++) {
              try {
                // List<dynamic> filteredObjects = existOrders
                //     .where(
                //       (obj) => obj["addon_id"] == parsed["addons"][i]["id"],
                //     )
                //     .toList();

                dynamic selItem = {};

                existOrders.forEach(
                  (var item) => {
                    if (item["addon_id"] == parsed["addons"][i]["id"])
                      {selItem = item},
                  },
                );

                print(selItem);

                if (selItem.length > 0) {
                  var addOnPrice = selItem["amount"];
                  parsed["addons"][i]["provider_addon_price_id"] =
                      selItem["id"] ?? "";
                  parsed["addons"][i]["amount"] = addOnPrice;
                  parsed["addons"][i]["addonsAmount"] = TextEditingController(
                    text: addOnPrice,
                  );
                } else {
                  parsed["addons"][i]["amount"] = "";
                  parsed["addons"][i]["addonsAmount"] = TextEditingController(
                    text: '',
                  );
                }
              } catch (err) {}
            }

            setState(() {
              addonsData = parsed["addons"];
            });
          } else {
            setState(() {
              addonsData = [];
            });
            // ignore: use_build_context_synchronously
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
    subscriptionData = json.decode(jsonData)["subscription"];

    var details = widget.subscriptiondetails["subscription_id"];
    print(details);

    callgetSubCatAPI();
    callAddonsAPI();
    // var data = widget.planName;

    // setState(() {
    //   selectedPack = widget.planName["packages"][0];
    // });

    // setState(() {
    //   packages = widget.planName["packages"] ?? [];
    // });
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
    final size = MediaQuery.of(context).size;
    final categories = subscriptionData["categories"];
    final services = categories[selectedCategory]["services"];

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header Row (fixed)
            Padding(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Row(
                children: [
                  CustomBackButton(),
                  SizedBox(width: size.width * 0.03),
                  Text(
                    widget.subscriptiondetails["isPackage"] == true?"Upgrade Plan":"Change Prices",
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    widget.subscriptiondetails["isPackage"] == true
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${widget.subscriptiondetails["category"]}\n${widget.subscriptiondetails["plan"]?["plan"] ?? widget.subscriptiondetails["subscription"] ?? ""}  (${widget.subscriptiondetails["selectedPackage"]?["jobs"] ?? widget.subscriptiondetails["jobs"] ?? ""} Jobs)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: size.width * 0.045,
                                ),
                              ),
                              Text(
                                "₹ ${widget.subscriptiondetails["selectedPackage"]?["amount"] ?? widget.subscriptiondetails["selectedPackage"]?["package"] ?? widget.subscriptiondetails["package"] ?? widget.subscriptiondetails["amount"] ?? "0"}",
                                style: TextStyle(
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${widget.subscriptiondetails["category"]}\n${widget.subscriptiondetails["subscription"]}  (${widget.subscriptiondetails["jobs"]} Jobs)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: size.width * 0.030,
                                ),
                              ),
                              Text(
                                "₹ ${widget.subscriptiondetails["package"] ?? widget.subscriptiondetails["amount"] ?? widget.subscriptiondetails["package_amount"] ?? "0"}",
                                style: TextStyle(
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                   widget.subscriptiondetails["isPackage"] == true
                        ?  Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                     
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                          onPressed: () {


                        Navigator.pushNamed(
                      // ignore: use_build_context_synchronously
                      context,
                      Config.PlanSummaryRouteName,
                      arguments: widget.subscriptiondetails,
                    ).then((value) {
    
    });

                      //         Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //       builder: (_) =>
                      //       //OTPScreen(phone: _phoneController.text),
                      //       UpdateSummaryScreen()
                      //   ),
                      // );
                            // Handle button press
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize
                                .min, // To prevent the Row from expanding unnecessarily
                            children: [
                              Icon(Icons.upgrade),
                              SizedBox(width: 8), // Add some spacing
                              Text('Upgrade Plan'),
                            ],
                          ),
                        ),
                      ],
                    ): SizedBox(height: 1),

                    // Category Tabs (NO SingleChildScrollView now)
                    SizedBox(
                      height: 100, // Set a fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis
                            .horizontal, // Important: Set scroll direction to horizontal
                        itemCount:
                            subcatDetails.length, // Number of items in the list
                        itemBuilder: (context, index) {
                          final bool isSelected = subCatIndex == index;
                          return GestureDetector(
                            onTap: () {
                              subCat = subcatDetails[index]["id"];
                              subCatIndex = index;
                              callgetServicesAPI(index);
                            },
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.transparent,
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      UtilClass.formatImageUrl(subcatDetails[index]["sub_image"]?.toString()),
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 40),
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subcatDetails[index]["sub_category"],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.black87,
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
                    SizedBox(height: size.height * 0.02),

                    Text(
                      "Enter your service price and discount",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: size.width * 0.04,
                      ),
                    ),

                    //sk
                    // Add this after the AC Type Selection section and before the "Enter your service price" text
                    SizedBox(height: deviceHeight * 0.02),

                    // Add-ons Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: _showAddOnsBottomSheet,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.blue,
                        ),
                        label: const Text(
                          "Add-ons",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    //sk end
                    SizedBox(height: deviceHeight * 0.02),

                    const Text(
                      "Enter your service price and discount",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: deviceHeight * 0.01),

                    // Service List
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

                    SizedBox(height: size.height * 0.12), // space for button
                  ],
                ),
              ),
            ),

            // Update Prices Button (fixed at bottom)
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: size.height * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      List<dynamic> servicesData = [];
                      List<dynamic> copiedList = [...subcatDetails];
                      for (int i = 0; i < copiedList.length; i++) {
                        var services = copiedList[i]["services"];
                        for (int j = 0; j < services.length; j++) {
                          try {
                            var amount = services[j]["acontroller"].text;
                            var discount = services[j]["dcontroller"].text;

                            if (amount.length > 0) {
                              servicesData.add({
                                "service_id": services[j]["id"],

                                "subscription_service_id":
                                    services[j]["subscription_service_id"] ??
                                    "",

                                "price": amount,
                                "discount": discount,
                                "type": services[j]["menuselect"] == "%"
                                    ? "percentage"
                                    : "amount",
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
                          "subscription_id":
                              widget.subscriptiondetails["subscription_id"],
                          "provider_id": userData["user_id"],
                          "category_id":
                              widget.subscriptiondetails["category_id"],
                          "sub_category_id": subCat,
                          "subscription":
                              widget.subscriptiondetails["subscription"],
                          "jobs": widget.subscriptiondetails["jobs"],
                          "package": widget.subscriptiondetails["package"],
                          "services": servicesData,
                        };

                        List<dynamic> addOnData = [];
                        try {
                          for (int a = 0; a < addonsData.length; a++) {
                            try {
                              var amountadd =
                                  addonsData[a]["addonsAmount"].text;

                              if (amountadd.length > 0) {
                                var dataAddon = {
                                  "addon_id": addonsData[a]["id"],
                                   "provider_addon_price_id": addonsData[a]["provider_addon_price_id"],

                                
                                  "price": amountadd,
                                };
                                addOnData.add(dataAddon);
                              }
                            } catch (err) {}
                          }
                        } catch (err) {}
                        print(addOnData);
                        if (addOnData.length > 0) {
                          data["addons"] = addOnData;
                        }

                        callUpdatesubscriptionAPI(data);
                      } else {
                        UtilClass.showAlertDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          message: "please add any one of the service",
                        );
                      }

                      print("cesData");

                      // debugPrint(
                      //   "serv Data: ${json.encode(subcatDetails)}",
                      // );
                      // debugPrint(
                      //   "add Data: ${json.encode(addonsData)}",
                      // );
                    },
                    child: Text(
                      "Update Prices",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.045,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                            var amount = double.parse(
                              subcatDetails[subCatIndex]["services"][index]["acontroller"]
                                  .text,
                            ).toInt();
                            var discount = 0;
                            try {
                              discount = double.parse(
                                subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                    .text,
                              ).toInt();
                            } catch (err) {
                              discount = 0;
                            }

                            var types =
                                subcatDetails[subCatIndex]["services"][index]["menuselectVal"];
                            totalvalue = (types == "%"
                                ? (amount - (amount * discount) / 100)
                                : (amount - discount).toDouble());
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
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
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
                          initialSelection:
                              subcatDetails[subCatIndex]["services"][index]["menuselect"],
                          onSelected: (String? value) {
                            // This is called when the user selects an item.
                            setState(() {
                              subcatDetails[subCatIndex]["services"][index]["menuselectVal"] =
                                  value;
                              dropdownValue = value!;
                            });

                            var data =
                                subcatDetails[subCatIndex]["services"][index];

                            // subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                            //         .text =
                            //     value;

                            double totalvalue = 0;
                            try {
                              // var amount = int.parse(
                              //   subcatDetails[subCatIndex]["services"][index]["acontroller"]
                              //       .text,
                              // );
                              var amount = double.parse(
                                subcatDetails[subCatIndex]["services"][index]["acontroller"]
                                    .text,
                              ).toInt();
                              var discount = 0;
                              try {
                                discount = double.parse(
                                  subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                      .text,
                                ).toInt();
                                // discount = int.parse(
                                //   subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                //       .text,
                                // );
                              } catch (err) {
                                discount = 0;
                              }

                              var types =
                                  subcatDetails[subCatIndex]["services"][index]["menuselectVal"];
                              totalvalue = (types == "%"
                                  ? (amount - (amount * discount) / 100)
                                  : (amount - discount).toDouble());
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
                              // var amount = int.parse(
                              //   subcatDetails[subCatIndex]["services"][index]["acontroller"]
                              //       .text,
                              // );
                              var amount = double.parse(
                                subcatDetails[subCatIndex]["services"][index]["acontroller"]
                                    .text,
                              ).toInt();
                              var discount = 0;
                              try {
                                // discount = int.parse(
                                //   subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                //       .text,
                                // );
                                discount = double.parse(
                                  subcatDetails[subCatIndex]["services"][index]["dcontroller"]
                                      .text,
                                ).toInt();
                              } catch (err) {
                                discount = 0;
                              }

                              var types =
                                  subcatDetails[subCatIndex]["services"][index]["menuselectVal"];
                              totalvalue = (types == "%"
                                  ? (amount - (amount * discount) / 100)
                                  : (amount - discount).toDouble());
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

  Widget _buildServiceCard(Map service, Size size, int index) {
    final priceController = TextEditingController(
      text: service["price"].toString(),
    );
    final discountPercentController = TextEditingController(
      text: service["discountPercent"].toString(),
    );
    final discountAmountController = TextEditingController(
      text: service["discountAmount"].toString(),
    );

    int calcTotal() {
      int price = int.tryParse(priceController.text) ?? 0;
      int discountPercent = int.tryParse(discountPercentController.text) ?? 0;
      int discountAmount = int.tryParse(discountAmountController.text) ?? 0;

      if (discountPercent > 0) {
        return price - ((price * discountPercent) ~/ 100);
      } else {
        return price - discountAmount;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: size.width * 0.18,
                width: size.width * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(service["image"]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Field
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Price",
                          prefixText: "₹ ",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        onChanged: (_) => setState(() {
                          service["price"] =
                              int.tryParse(priceController.text) ?? 0;
                        }),
                      ),
                    ),

                    // Discount Fields
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            child: TextField(
                              controller: discountPercentController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Discount %",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.all(10),
                              ),
                              onChanged: (_) => setState(() {
                                service["discountPercent"] =
                                    int.tryParse(
                                      discountPercentController.text,
                                    ) ??
                                    0;
                              }),
                            ),
                          ),
                        ),
                        // Expanded(
                        //   child: Container(
                        //     margin: const EdgeInsets.only(left: 6),
                        //     child: TextField(
                        //       controller: discountAmountController,
                        //       keyboardType: TextInputType.number,
                        //       decoration: InputDecoration(
                        //         labelText: "Discount ₹",
                        //         border: OutlineInputBorder(
                        //           borderRadius: BorderRadius.circular(8),
                        //         ),
                        //         isDense: true,
                        //         contentPadding: const EdgeInsets.all(10),
                        //       ),
                        //       onChanged: (_) => setState(() {
                        //         service["discountAmount"] =
                        //             int.tryParse(discountAmountController.text) ??
                        //                 0;
                        //       }),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.01),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              service["name"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size.width * 0.04,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.005),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Total ₹ ${calcTotal()}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size.width * 0.045,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show Add-ons Bottom Sheet
  void _showAddOnsBottomSheet() {
    if (addonsData.isEmpty) {
      UtilClass.showAlertDialog(
        // ignore: use_build_context_synchronously
        context: context,
        message: "Addons Not Found",
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // 60% device height
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add-ons Jobs",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter prices for additional services",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Add-ons List with inner scrolling
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: addonsData.length,
                  itemBuilder: (context, index) {
                    var job = addonsData[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              job['addon_service'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: addonsData[index]["addonsAmount"],

                              onChanged: (value) {
                                addonsData[index]["addonsAmount"].text = value;

                                //      setState(() {
                                //   addonsData[index]["services"][index]["ttotal"] =
                                //       totalvalue.toString();

                                //   // You can also update other properties of the object here
                                // });
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: "₹ 0",
                                hintStyle: const TextStyle(fontSize: 13),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Proceed Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showProceedButton
                      ? () {
                          Navigator.pop(context);
                          // Handle proceed action here
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showProceedButton
                        ? Colors.green
                        : Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Proceed",
                    style: TextStyle(
                      color: _showProceedButton ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
