import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import '../../../../components/custom_back_button.dart';
import '../../../../utils/config.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:gobuddy/components/bottom_sheet_utils.dart';
// Global variable to track if there are active or expired subscriptions
bool hasSubscriptions = true; // Set this based on your actual data

class SubscriptionScreen extends StatefulWidget {
  final bool issubscription;

  const SubscriptionScreen({super.key, required this.issubscription});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.issubscription
        ? MySubscriptionsScreen()
        : CreateSubscriptionScreen();
  }
}

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  // Sample JSON (you can fetch this from API)
  final String subscriptionJson = '''
  {
    "subscriptions": [
      
    ]
  }
  ''';


  final List<Map<String, dynamic>> jobPlansJson = [
  {
    "plan_id": "1",
    "plan": "Basic Plan",
    "packages": [
      {"id": "1", "jobs": "20", "amount": "999.00"},
      {"id": "2", "jobs": "40", "amount": "1499.00"}
    ]
  },
  {
    "plan_id": "2",
    "plan": "Advanced Plan",
    "packages": [
      {"id": "3", "jobs": "60", "amount": "2399.00"},
    ]
  }
];

  bool isPackageSelected = false; // for Add button state
  int? selectedPackage; // selected package index

  // Job Packages JSON
  final List<Map<String, dynamic>> jobPackages = [
    {"jobs": 20, "price": 999},
    {"jobs": 40, "price": 1499},
    {"jobs": 60, "price": 2399},
  ];

  // late List subscriptions;
  List<dynamic> subscriptions = [];
  int selectedIndex = 0; // Default tab selected
  dynamic subscriptionsDetails = [];
  dynamic userData = {};
  dynamic subscription ;
   List<dynamic> addonsData = [];
 List<dynamic>  packages = [];

  dynamic selectedPack = {};
  @override
  void initState() {
    super.initState();
    // final data = json.decode(subscriptionJson);
    // subscriptions = data["subscriptions"];

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    callgetSubscriptionsAPI();
    
  }
  void callgetPlansAPI(sub) async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.packagesApi, {
        "subscription_id": sub["subscription_id"],
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed =value;
          if (parsed["status"] == "valid") {
            packages = parsed["plans"];

            setState(() {
              selectedPack = parsed["plans"][0];
            });

            setState(() {
              packages = parsed["plans"];
            });

            _showJobPackageBottomSheet({});
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

  Future<bool> _checkIsProviderVerified() async {
    return await UtilClass.checkProviderApprovalLive();
  }

  void _showVerificationPendingDialog() {
    UtilClass.showVerificationPendingDialog(context);
  }

  void callgetSubscriptionsAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      // ignore: use_build_context_synchronously
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.subscriptionorders, {
        "provider_id": userData["user_id"] ?? "",
      }).then((value) async {
        UtilClass.hideProgress();
        dynamic parsed = {};
        try {
          parsed = value;
          if (parsed["status"] == "valid") {
            subscriptions = parsed["data"];

            setState(() {
              subscriptions = parsed["data"];
            });

             subscription = subscriptions[selectedIndex];
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CustomBackButton(),
                  SizedBox(width: size.width * 0.03),
                  Text(
                    "My Subscriptions",
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),

              // Create New Subscription Package
              GestureDetector(
                onTap: () async {
                  final isVerified = await _checkIsProviderVerified();
                  if (!isVerified) {
                    _showVerificationPendingDialog();
                    return;
                  }
                  // Navigate to create subscription screen
                  Navigator.pushNamed(
                    // ignore: use_build_context_synchronously
                    context,
                    Config.createPackageRouteName,
                  ).then((_) {
                    callgetSubscriptionsAPI();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Create New Subscription Package",
                        style: TextStyle(fontSize: size.width * 0.03),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.add,
                          color: Colors.green,
                          size: size.width * 0.06,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Tabs
              SizedBox(
                height: 50, // Adjust the height as needed
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: subscriptions.asMap().entries.map((entry) {
                      int index = entry.key;
                      dynamic item = entry.value;
                      return _buildTab(
                        item["category"],
                        index,
                        item["category"],
                        size,
                      );
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Subscription Card
             subscription != null ? _buildSubscriptionCard(subscription, size): SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, String activeTitle, Size size) {
    final isActive = index == selectedIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
          if (selectedIndex < subscriptions.length) {
            subscription = subscriptions[selectedIndex];
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.012,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontSize: size.width * 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map subscription, Size size) {
    final status = subscription["status_text"]?.toString() ??
        ((subscription["status"] == 1 || subscription["status"] == "1")
            ? "Active"
            : "Inactive");
    final isActive = status.toLowerCase() == "active";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Price + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${subscription["category"] ?? ""}\n${subscription["subscription"] ?? ""}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.045,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: size.width * 0.035,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    "₹ ${subscription["package"] ?? subscription["amount"] ?? "0"}",
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),

          // Job Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildJobInfo(
                "Total Jobs",
                (subscription["jobs"] ?? subscription["package_value"] ?? "0").toString(),
                size,
              ),
              _buildJobInfo("Used", (subscription["used"] ?? 0).toString(), size),
              _buildJobInfo("Missed", (subscription["missed"] ?? 0).toString(), size),
              _buildJobInfo(
                "Remaining",
                (subscription["remaining"] ?? 0).toString(),
                size,
              ),
            ],
          ),
          Divider(height: size.height * 0.03, thickness: 1),

          // Subscribed Date
          Text(
            "Subscribed on",
            style: TextStyle(color: Colors.grey, fontSize: size.width * 0.035),
          ),
          Text(
            subscription["subscribedon"]?.toString() ?? "",
            style: TextStyle(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: size.height * 0.02),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isActive)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => ChangePricesScreen()),
                    // );
                   

 subscription["isPackage"] = false;

 Navigator.pushNamed(
                      // ignore: use_build_context_synchronously
                      context,
                      Config.changePriceRouteName,
                      arguments: subscription,
                    ).then((value) {
      callgetSubscriptionsAPI();
   
    });







                  },
                  child: const Text("Change Prices"),
                ),
              SizedBox(width: size.width * 0.03),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.green : Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                   callgetPlansAPI(subscription);
                           
                },
                child: Text(isActive ? "Update" : "Renew"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo(String label, String value, Size size) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey, fontSize: size.width * 0.035),
        ),
        SizedBox(height: size.height * 0.005),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.04,
          ),
        ),
      ],
    );
  }

  void _showJobPackageBottomSheet(packagesData) {
   BottomSheetUtils.showJobPackageSheet(
    context: context,
    plansJson: packages,
    onSubmit: (selectedPackage) {
      print("Selected Package ID: ${selectedPackage['id']}");
      print("Selected Package Jobs: ${selectedPackage['jobs']}");
      print("Selected Package: $selectedPackage");
      subscription["selectedPackage"] = selectedPackage;
      subscription["isPackage"] = true;
      subscription["plan"] = packages[selectedPackage["selectedIndex"]];
       Navigator.pushNamed(
                      // ignore: use_build_context_synchronously
                      context,
                      Config.changePriceRouteName,
                      arguments: subscription,
                    );

//       Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => UpdatePlanScreen(
//       selectedPackage: {
//     "id": subscription["id"],
//     "jobs": subscription["jobs"],
//     "amount": subscription["amount"],
//   },
//     ),
//   ),
// );
//  Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (_) => const UpdatePlanScreen()),
//                       );

    },
  );
  }
}

class CreateSubscriptionScreen extends StatefulWidget {
  const CreateSubscriptionScreen({super.key});

  @override
  State<CreateSubscriptionScreen> createState() =>
      _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<CreateSubscriptionScreen> {
  void _showVerificationPendingDialog() {
    UtilClass.showVerificationPendingDialog(context);
  }

  Future<bool> _checkIsProviderVerified() async {
    return await UtilClass.checkProviderApprovalLive();
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          height: deviceHeight,
          width: deviceWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Top Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: deviceWidth * 0.04,
                  vertical: deviceHeight * 0.015,
                ),
                child: Row(
                  children: [
                    CustomBackButton(),
                    SizedBox(width: deviceWidth * 0.02),
                    const Text(
                      "Create My Subscription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: deviceHeight * 0.05),

              /// Illustration
              SizedBox(
                height: deviceHeight * 0.25,
                child: Image.asset(
                  "assets/images/subscription.png", // replace with your image asset
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: deviceHeight * 0.05),

              /// English Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
                child: _buildText(
                  "Select your Service Category/Type and add prices to the services you want to provide to create the package.",
                ),
              ),

              SizedBox(height: deviceHeight * 0.015),

              /// Telugu Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
                child: _buildText(
                  "మీ చెక్కౌట్ క్యాటగిరీ/రకాన్ని ఎంచుకుని, మీరు అందించాలనుకుంటున్న సర్వీస్ ఆర్డర్లకు ధరలను ఇన్పుట్ చేసిన ప్యాకేజీని సృష్టించండి.",
                ),
              ),

              SizedBox(height: deviceHeight * 0.04),

              /// Footer text
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.08),
              //   child: _buildText(
              //     'Watch "How to Create Subscription Package" video in tutorials for detailed assistance.',
              //   ),
              // ),

              // const Spacer(),

              

              /// Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: deviceWidth * 0.08,
                  vertical: deviceHeight * 0.03,
                ),
                child: _buildYellowButton(
                  title: "My Active Subscriptions ",
                  onPressed: () {
                    String providerId = "";
                    final userDataValue = Preferences.getUserDetails();
                    if (userDataValue != null) {
                      try {
                        final u = json.decode(userDataValue);
                        providerId = (u["user_id"] ?? u["id"])?.toString() ?? "";
                      } catch (_) {}
                    }
                    Navigator.pushNamed(
                      context,
                      arguments: {
                        "provider_id": providerId,
                      },
                      Config.getActiveSubscriptionsRouteName,
                    );
                  },
                ),
              ),

                 Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: deviceWidth * 0.08,
                  vertical: deviceHeight * 0.03,
                ),
                child: _buildYellowButton(
                  title: "Get Started",
                  onPressed: () async {
                    final isVerified = await _checkIsProviderVerified();
                    if (!isVerified) {
                      _showVerificationPendingDialog();
                      return;
                    }
                    Navigator.pushNamed(
                      // ignore: use_build_context_synchronously
                      context,
                      Config.createPackageRouteName,
                    ).then((_) {
                      if (mounted) {
                        Navigator.pushReplacementNamed(
                          context,
                          Config.mySubscriptionsRouteName,
                          arguments: {'issubscription': true},
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Text
  Widget _buildText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
    );
  }

  /// Reusable Button
  Widget _buildYellowButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD731), // Yellow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
