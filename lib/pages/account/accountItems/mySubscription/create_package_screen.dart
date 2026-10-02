import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/boras_touch_models/get_subscriptions_model.dart';
import 'package:gobuddy/pages/account/accountItems/mySubscription/technician_services_prices.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';

import 'package:gobuddy/utils/util_class.dart';
import '../../../../utils/config.dart';
import 'Ac_tec_basic_plan.dart';

class CreatePackageScreen extends StatefulWidget {
  const CreatePackageScreen({super.key});

  @override
  State<CreatePackageScreen> createState() => _CreatePackageScreenState();
}

class _CreatePackageScreenState extends State<CreatePackageScreen> {
  List<dynamic> planDet = [];
  GetAllCategoriesModel? pushintoallCategoriesModel;
  List<Category> allCategories = [];
  bool isLoading = false;

  dynamic userData = {};

  @override
  void initState() {
    super.initState();

    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isVerified = await UtilClass.checkProviderApprovalLive();
      if (!isVerified && mounted) {
        Navigator.pop(context);
        UtilClass.showVerificationPendingDialog(context);
      }
    });

    callBasicPackagesAPI();
    _getAllCategories();
  }

  Future<void> _getAllCategories() async {
    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(
        context: context,
        message: "No Internet Connection",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String userPincode =
          (userData?['pincode'] ??
                  userData?['pin_code'] ??
                  userData?['postal_code'] ??
                  "533431")
              .toString();
      if (userPincode.trim().isEmpty) userPincode = "533431";

      final response = await Repository.postApiService(
        EndPoints.getSubscriptionsforProvider,
        {"pincode": userPincode},
      );

      Map<String, dynamic> jsonResponse;

      if (response is String) {
        jsonResponse = json.decode(response as String);
      } else {
        jsonResponse = response;
      }

      if (jsonResponse["status"] == "valid") {
        setState(() {
          pushintoallCategoriesModel = GetAllCategoriesModel.fromJson(
            jsonResponse,
          );
          allCategories = pushintoallCategoriesModel?.categories ?? [];
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

  void callBasicPackagesAPI() async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      await Repository.postApiServiceWithJson(EndPoints.packagesApi, {}).then((
        value,
      ) async {
        dynamic parsed = {};
        try {
          parsed = value;
          if (parsed["status"] == "valid") {
            setState(() {
              planDet = parsed["plans"];
            });
          } else {
            UtilClass.showAlertDialog(
              context: context,
              message: parsed["message"],
            );
          }
        } catch (e) {
          print(e);
        }
      });
    } else {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  // void _showPlanSelectionDialog(Category category, dynamic planDet) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return PlanSelectionDialog(category: category, plans: planDet);
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header with Gradient
            Container(
              width: deviceWidth,
              padding: EdgeInsets.symmetric(
                horizontal: deviceWidth * 0.05,
                vertical: deviceHeight * 0.02,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFFC8BB47), Color(0xFF25AC2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: _buildBackButton(),
                      ),
                      SizedBox(width: deviceWidth * 0.03),
                      const Text(
                        "Create Your Package",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: deviceHeight * 0.03),
                  const Text(
                    "Select Your Skill Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: deviceHeight * 0.01),
                ],
              ),
            ),

            SizedBox(height: deviceHeight * 0.02),

            /// Category List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF25AC2C),
                      ),
                    )
                  : allCategories.isEmpty
                  ? const Center(
                      child: Text(
                        "No categories found",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: deviceWidth * 0.05,
                      ),
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final category = allCategories[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: deviceHeight * 0.02),
                          child: GestureDetector(
                            onTap: () {
                              // _showPlanSelectionDialog(category, planDet);

                              Navigator.pushNamed(
                                context,
                                arguments: {
                                  "category_name": category.category ?? "",
                                  "category_id": category.id ?? "",
                                  "category_image": category.image ?? "",
                                },
                                Config.getSubscriptionplasnRouteName,
                              );
                            },

                            child: _buildCategoryCard(
                              category,
                              deviceWidth,
                              deviceHeight,
                            ),
                          ),
                        );
                      },
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

  /// Category Card
  Widget _buildCategoryCard(
    Category category,
    double deviceWidth,
    double deviceHeight,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: deviceWidth * 0.04,
        vertical: deviceHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Service Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              UtilClass.formatImageUrl(category.image),
              height: 55,
              width: 55,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 55,
                  width: 55,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.grey,
                    size: 28,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 55,
                  width: 55,
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(width: deviceWidth * 0.05),

          /// Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.category ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if ((category.subCategories ?? []).isNotEmpty)
                  Text(
                    "${category.subCategories!.length} Sub-services",
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
              ],
            ),
          ),

          /// Arrow
          Container(
            height: 35,
            width: 35,
            decoration: const BoxDecoration(
              color: Color(0xFFE9FFE9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.green,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog version of PlanSelectionScreen
// class PlanSelectionDialog extends StatefulWidget {
//   final Category category;
//   final dynamic plans;

//   const PlanSelectionDialog(
//       {super.key, required this.category, required this.plans});

//   @override
//   State<PlanSelectionDialog> createState() => _PlanSelectionDialogState();
// }

// class _PlanSelectionDialogState extends State<PlanSelectionDialog> {
//   int? selectedIndex;

//   @override
//   Widget build(BuildContext context) {
//     final deviceHeight = MediaQuery.of(context).size.height;
//     final deviceWidth = MediaQuery.of(context).size.width;

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.06),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             SizedBox(height: deviceHeight * 0.02),

//             /// Header Row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const SizedBox(width: 40),
//                 Text(
//                   widget.category.category ?? "",
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.black87),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),

//             SizedBox(height: deviceHeight * 0.02),

//             /// Subheading
//             const Text(
//               "Choose Your Plan",
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black54,
//               ),
//             ),

//             SizedBox(height: deviceHeight * 0.03),

//             /// Plans List
//             Column(
//               children: List.generate(widget.plans.length, (index) {
//                 return Padding(
//                   padding: EdgeInsets.only(bottom: deviceHeight * 0.015),
//                   child: _buildPlanCard(
//                     index,
//                     widget.plans[index]["plan"] ?? "",
//                     deviceWidth,
//                     deviceHeight,
//                   ),
//                 );
//               }),
//             ),

//             SizedBox(height: deviceHeight * 0.02),

//             /// Continue Button
//             GestureDetector(
//               onTap: selectedIndex != null
//                   ? () {
//                       Navigator.pop(context);
//                       Navigator.pushNamed(
//                         context,
//                         Config.technicianServicesPricesRouteName,
//                         arguments: {
//                           "categoryName": widget.category,
//                           "planName": widget.plans[selectedIndex],
//                           "planType": widget.plans[selectedIndex]["plan"] ?? "",
//                         },
//                       );
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                               "${widget.plans[selectedIndex]["plan"]} Selected"),
//                         ),
//                       );
//                     }
//                   : null,
//               child: Container(
//                 width: double.infinity,
//                 height: deviceHeight * 0.06,
//                 decoration: BoxDecoration(
//                   color: selectedIndex != null
//                       ? const Color(0xFF429321)
//                       : Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 alignment: Alignment.center,
//                 child: Text(
//                   "Continue",
//                   style: TextStyle(
//                     color: selectedIndex != null
//                         ? Colors.white
//                         : Colors.grey.shade600,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),

//             SizedBox(height: deviceHeight * 0.03),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Plan Card Widget
//   Widget _buildPlanCard(int index, String title, double w, double h) {
//     final bool isSelected = selectedIndex == index;

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedIndex = index;
//         });
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: w * 0.05,
//           vertical: h * 0.02,
//         ),
//         decoration: BoxDecoration(
//           gradient: isSelected
//               ? const LinearGradient(
//                   colors: [Color(0xFFFFF176), Color(0xFF66BB6A)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//               : null,
//           color: isSelected ? null : Colors.white,
//           border: Border.all(
//             color: isSelected ? Colors.transparent : Colors.grey.shade400,
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             /// Texts
//             Expanded(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),

//             /// Tick Mark if selected
//             if (isSelected)
//               Container(
//                 height: 26,
//                 width: 26,
//                 decoration: const BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white,
//                 ),
//                 child: const Icon(
//                   Icons.check,
//                   color: Colors.green,
//                   size: 18,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
