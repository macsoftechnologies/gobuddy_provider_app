import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/pages/account/accountItems/mySubscription/update_plan_summary.dart';

import '../../../../components/custom_back_button.dart';
// import 'package:providerapp_gobuddy/screens/subscriptionScreens/update_plan_summary.dart';
//
// import '../../utilites/custombackbutton.dart';

class UpdatePlanScreen extends StatefulWidget {
  const UpdatePlanScreen({super.key});

  @override
  State<UpdatePlanScreen> createState() => _UpdatePlanScreenState();
}

class _UpdatePlanScreenState extends State<UpdatePlanScreen> {
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
          "image": "assets/images/ac.png",
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

  late Map<String, dynamic> subscriptionData;
  int selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    subscriptionData = json.decode(jsonData)["subscription"];
  }

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
                  Text("Update Plan",
                      style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            "${subscriptionData["title"]}\n${subscriptionData["plan"]}  (${subscriptionData["jobs"]} Jobs)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: size.width * 0.045)),
                        Text("₹ ${subscriptionData["price"]}",
                            style: TextStyle(
                                fontSize: size.width * 0.05,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),

                    // Category Tabs (NO SingleChildScrollView now)
                    Row(
                      children: List.generate(categories.length, (index) {
                        final category = categories[index];
                        final isSelected = index == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedCategory = index);
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: size.width * 0.05),
                            child: Column(
                              children: [
                                Container(
                                  height: size.width * 0.2,
                                  width: size.width * 0.2,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade400,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: AssetImage(category["image"]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(category["name"],
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    height: 2,
                                    width: size.width * 0.2,
                                    color: Colors.green,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: size.height * 0.02),

                    Text("Enter your service price and discount",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: size.width * 0.04)),

                    SizedBox(height: size.height * 0.015),

                    // Service List
                    Column(
                      children: List.generate(services.length, (index) {
                        final service = services[index];
                        return _buildServiceCard(service, size, index);
                      }),
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
                      padding:
                      EdgeInsets.symmetric(vertical: size.height * 0.02),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateSummaryScreen(
                            subscription: subscriptionData,
                          ),
                        ),
                      );
                      debugPrint(
                          "Updated Data: ${json.encode(subscriptionData)}");
                    },
                    child: Text("Proceed To Update",
                        style: TextStyle(
                            color: Colors.white, fontSize: size.width * 0.045)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map service, Size size, int index) {
    final priceController =
    TextEditingController(text: service["price"].toString());
    final discountPercentController =
    TextEditingController(text: service["discountPercent"].toString());
    final discountAmountController =
    TextEditingController(text: service["discountAmount"].toString());

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
              offset: const Offset(1, 2))
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
                      image: AssetImage(service["image"]), fit: BoxFit.cover),
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
                                service["discountPercent"] = int.tryParse(
                                    discountPercentController.text) ??
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
            child: Text(service["name"],
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: size.width * 0.04)),
          ),
          SizedBox(height: size.height * 0.005),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Total ₹ ${calcTotal()}",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: size.width * 0.045)),
          ),
        ],
      ),
    );
  }
}
