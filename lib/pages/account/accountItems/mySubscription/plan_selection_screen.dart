import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobuddy/models/boras_touch_models/get_packages_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  int? selectedIndex;
  bool isLoading = false;
  GetPlansModel? pushintoborasModel;
  List<PlanDataOne> planData = [];
  String? categoryName;
  dynamic categoryId;
  String? categoryImage;

  /// Group plans by plan_id → Basic Plan, Advanced Plan as separate cards
  List<Map<String, dynamic>> get groupedPlans {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var plan in planData) {
      final planId = plan.planId ?? "";
      if (!grouped.containsKey(planId)) {
        grouped[planId] = {
          "plan_id": planId,
          "plan": plan.plan ?? "",
          "packages": <PlanDataOne>[],
        };
      }
      (grouped[planId]!["packages"] as List<PlanDataOne>).add(plan);
    }
    return grouped.values.toList();
  }

  /// Get starting amount (lowest package price) in selected plan
  String get selectedPlanPrice {
    if (selectedIndex == null) return "";
    final packages =
        groupedPlans[selectedIndex!]["packages"] as List<PlanDataOne>;
    if (packages.isEmpty) return "0";
    double minAmount = double.infinity;
    for (var p in packages) {
      final amt = double.tryParse(p.amount ?? "0") ?? 0;
      if (amt > 0 && amt < minAmount) {
        minAmount = amt;
      }
    }
    if (minAmount == double.infinity) {
      minAmount = double.tryParse(packages.first.amount ?? "0") ?? 0;
    }
    return minAmount % 1 == 0
        ? minAmount.toInt().toString()
        : minAmount.toStringAsFixed(2);
  }

  /// Get selected plan name
  String get selectedPlanName {
    if (selectedIndex == null) return "";
    return groupedPlans[selectedIndex!]["plan"] ?? "";
  }

  /// Get selected plan id
  String get selectedPlanId {
    if (selectedIndex == null) return "";
    return groupedPlans[selectedIndex!]["plan_id"] ?? "";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      categoryName = args['category_name'];
      categoryId = args['category_id'];
      categoryImage = args['category_image'];

      print("Category Name is $categoryName");
      print("Category ID is $categoryId");
      print("Category Image is $categoryImage");
    }

    _getServicePlans();
  }

  Future<void> _getServicePlans() async {
    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(
          context: context, message: "No Internet Connection");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Repository.getApiService(
          EndPoints.getplansforProviderSubscription);

      Map<String, dynamic> jsonResponse;
      if (response is String) {
        jsonResponse = json.decode(response as String);
      } else {
        jsonResponse = response;
      }

      if (jsonResponse["status"] == true) {
        setState(() {
          pushintoborasModel = GetPlansModel.fromJson(jsonResponse);
          planData = pushintoborasModel?.data ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse["message"] ?? "Something went wrong",
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Top Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: deviceWidth * 0.04,
                vertical: deviceHeight * 0.02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    categoryName ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: deviceHeight * 0.02),

            /// Subtitle
            const Text(
              "Choose Your Plan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black45,
              ),
            ),

            SizedBox(height: deviceHeight * 0.03),

            /// Plans List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3AAD41),
                      ),
                    )
                  : groupedPlans.isEmpty
                      ? const Center(
                          child: Text(
                            "No plans available",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black45,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.05),
                          itemCount: groupedPlans.length,
                          itemBuilder: (context, index) {
                            final plan = groupedPlans[index];
                            final List<PlanDataOne> packages =
                                plan["packages"] as List<PlanDataOne>;

                            /// Subtitle: "20 Jobs  &  3 Months"
                            final String subtitle = packages
                                .map((p) => p.package ?? "")
                                .join("  &  ");

                            final bool isSelected = selectedIndex == index;

                            return Padding(
                              padding:
                                  EdgeInsets.only(bottom: deviceHeight * 0.02),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: deviceWidth * 0.05,
                                    vertical: deviceHeight * 0.022,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFD4C84A),
                                              Color(0xFF3AAD41),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isSelected ? null : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      /// Plan name + subtitle
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan["plan"] ?? "",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            SizedBox(
                                                height: deviceHeight * 0.006),
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isSelected
                                                    ? Colors.white70
                                                    : Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      /// Check icon if selected
                                      if (isSelected)
                                        Container(
                                          height: 28,
                                          width: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),

            /// Continue Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: deviceWidth * 0.05,
                vertical: deviceHeight * 0.03,
              ),
              child: GestureDetector(
                onTap: selectedIndex != null
                    ? () {
                        Navigator.pushNamed(
                          context,
                          Config.discountsaddingSection,
                          arguments: {
                            "category_id": categoryId ?? "",
                            "category_name": categoryName ?? "",
                            "category_image": categoryImage ?? "",
                            "plan_id": selectedPlanId,      
                            "plan_name": selectedPlanName,  
                            "plan_price": selectedPlanPrice, 
                           "plan_packages": groupedPlans[selectedIndex!]["packages"], 
                          },
                        );
                      }
                    : null, 
                child: Container(
                  width: double.infinity,
                  height: deviceHeight * 0.065,
                  decoration: BoxDecoration(
                    color: selectedIndex != null
                        ? const Color(0xFF3AAD41)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedIndex != null
                          ? Colors.white
                          : Colors.grey.shade500,
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
}