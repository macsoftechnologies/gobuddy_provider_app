import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/boras_touch_models/get_packages_model.dart';
import 'package:gobuddy/models/boras_touch_models/getaddons_borasmodel.dart';
import 'package:gobuddy/models/boras_touch_models/getservicesbora_model.dart';
import 'package:gobuddy/models/boras_touch_models/getsubcategorisboras_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';

class AcTechnicianScreen extends StatefulWidget {
  const AcTechnicianScreen({super.key});

  @override
  State<AcTechnicianScreen> createState() => _AcTechnicianScreenState();
}

class _AcTechnicianScreenState extends State<AcTechnicianScreen> {
  double deviceHeight = 0;
  double deviceWidth = 0;
   dynamic userData = {};

  // ── Args ──────────────────────────────────────────────
  String? categoryName;
  dynamic categoryId;
  String? categoryImage;
  String? planId;
  String? planName;
  String? planPrice;
  List<PlanDataOne> planPackages = []; 

  // ── State flags ───────────────────────────────────────
  bool isSubCatLoading = false;
  bool isServicesLoading = false;
  bool isAddonsLoading = false;
  bool planAdded = false;

  // ── Selection ─────────────────────────────────────────
  int? selectedSubIndex;
  String? selectedSubcategoryId;
  int? selectedPackageIndex; 

  // ── Data ──────────────────────────────────────────────
  GetSubCategoriesModel? pushintosubcategoryModel;
  List<SubCategory> getsubcategories = []; 

  GetServicesModel? pushintoservicesmodel;
  List<Services> getservices = [];

  GetAddonsModel? pushintoAddonsModel;
  List<Addon> getaddons = [];

  // ── Service input controllers (keyed by service.id to persist across subcategories) ──
  final Map<String, TextEditingController> priceControllers = {};
  final Map<String, TextEditingController> discountControllers = {};
  final Map<String, String> discountTypes = {}; // "percentage" | "amount"
  final Map<String, Services> allKnownServices = {};

  // ── Addon input controllers ───────────────────────────
  final Map<int, TextEditingController> addonPriceControllers = {};
  final Set<int> selectedAddonIndexes = {};

  // ── Initialization flag ─────────────────────────────
  bool _isInitialized = false;

  // ─────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    final userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }

    print(" reciving the Provider Id ${userData['user_id']}");
  

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      categoryName  = args['category_name'];
      categoryId    = args['category_id'];
      categoryImage = args['category_image'];
      planId        = args['plan_id'];
      planName      = args['plan_name'];
      planPrice     = args['plan_price'];
      planPackages  = (args['plan_packages'] as List<PlanDataOne>?) ?? [];
    }
    _getSubCategories();
    _getMyAddons();
  }

  @override
  void dispose() {
    priceControllers.values.forEach((c) => c.dispose());
    discountControllers.values.forEach((c) => c.dispose());
    addonPriceControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // API — Subcategories
  // ─────────────────────────────────────────────────────
  Future<void> _getSubCategories() async {
    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    setState(() => isSubCatLoading = true);

    try {
      final response = await Repository.postApiService(
        EndPoints.getSubcategoriesData,
        {"category_id": categoryId ?? ""},
      );
      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : response;

      if (jsonResponse["status"] == "valid") {
        setState(() {
          pushintosubcategoryModel =
              GetSubCategoriesModel.fromJson(jsonResponse);
          getsubcategories =
              pushintosubcategoryModel?.subCategory ?? [];
          if (getsubcategories.isNotEmpty && selectedSubIndex == null) {
            selectedSubIndex = 0;
            selectedSubcategoryId = getsubcategories[0].id ?? "";
          }
        });

        if (selectedSubcategoryId != null && selectedSubcategoryId!.isNotEmpty) {
          _getServices(selectedSubcategoryId!);
        }
      } else {
        UtilClass.showAlertDialog(
            context: context,
            message: jsonResponse["message"] ?? "Something went wrong");
      }
    } catch (e) {
      print("_getSubCategories error: $e");
    } finally {
      setState(() => isSubCatLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // API — Services  (called on subcategory tap)
  // ─────────────────────────────────────────────────────
  Future<void> _getServices(String subCategoryId) async {
    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }
    setState(() {
      isServicesLoading = true;
      getservices.clear();
      // NOTE: Do NOT clear priceControllers, discountControllers, or discountTypes
      // so prices entered by the user are retained when switching subcategories!
    });
    try {
      final response = await Repository.postApiService(
        EndPoints.getservices,
        {"sub_category_id": subCategoryId},
      );
      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : response;

      if (jsonResponse["status"] == "valid") {
        setState(() {
          pushintoservicesmodel = GetServicesModel.fromJson(jsonResponse);
          getservices = pushintoservicesmodel?.services ?? [];

          // Initialise controllers for services if not already existing
          for (int i = 0; i < getservices.length; i++) {
            final sId = getservices[i].id ?? i.toString();
            allKnownServices[sId] = getservices[i];
            if (!priceControllers.containsKey(sId)) {
              final defaultPrice = (getservices[i].price != null &&
                      getservices[i].price!.isNotEmpty &&
                      getservices[i].price != "0")
                  ? getservices[i].price!
                  : "";
              priceControllers[sId] = TextEditingController(text: defaultPrice);
            }
            if (!discountControllers.containsKey(sId)) {
              discountControllers[sId] = TextEditingController(text: "0");
            }
            if (!discountTypes.containsKey(sId)) {
              discountTypes[sId] = "percentage";
            }
          }
        });
      } else {
        UtilClass.showAlertDialog(
            context: context,
            message: jsonResponse["message"] ?? "Something went wrong");
      }
    } catch (e) {
      print("_getServices error: $e");
    } finally {
      setState(() => isServicesLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // API — Addons
  // ─────────────────────────────────────────────────────
  Future<void> _getMyAddons() async {
    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    setState(() => isAddonsLoading = true);

    try {
      final response = await Repository.postApiService(
        EndPoints.getAddons,
        {"category_id": categoryId ?? ""},
      );
      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : response;

      if (jsonResponse["status"] == "valid") {
        setState(() {
          pushintoAddonsModel = GetAddonsModel.fromJson(jsonResponse);
          getaddons = pushintoAddonsModel?.addons ?? [];
          addonPriceControllers.values.forEach((c) => c.dispose());
          addonPriceControllers.clear();
          selectedAddonIndexes.clear();

          for (int i = 0; i < getaddons.length; i++) {
            addonPriceControllers[i] = TextEditingController();
          }
        });
      }
    } catch (e) {
      print("_getMyAddons error: $e");
    } finally {
      setState(() => isAddonsLoading = false);
    }
  }

  void _proceedWithSubscription() {
    // ── Services payload (collected across all subcategories configured) ──
    final servicesPayload = <Map<String, dynamic>>[];
    for (final entry in allKnownServices.entries) {
      final sId = entry.key;
      final service = entry.value;
      final price = double.tryParse(priceControllers[sId]?.text ?? "") ?? 0;
      final discount = double.tryParse(discountControllers[sId]?.text ?? "") ?? 0;
      if (price > 0) {
        servicesPayload.add({
          "service_id": int.tryParse(service.id?.toString() ?? sId) ?? (service.id ?? sId),           
          "price":      price,
          "discount":   discount,
          "type":       discountTypes[sId] ?? "percentage",
        });
      }
    }

    if (servicesPayload.isEmpty) {
      UtilClass.showAlertDialog(
        context: context,
        message: "Please enter a price for at least one service before proceeding with subscription.",
      );
      return;
    }

    // ── Addons payload ────────────────────────────────
    final addonsPayload = <Map<String, dynamic>>[];
    for (final idx in selectedAddonIndexes) {
      final price = double.tryParse(addonPriceControllers[idx]?.text ?? "") ?? 0;
      addonsPayload.add({
        "addon_id": getaddons[idx].id,               // ✅ Addon.id
        "price":    price,
      });
    }

    // ── Selected package ──────────────────────────────
    final selectedPkg = selectedPackageIndex != null
        ? planPackages[selectedPackageIndex!]
        : null;

    // ── Final payload ─────────────────────────────────
    final payload = {
      "provider_id":   userData["user_id"]??"",                          // fill from SharedPreferences
      "category_id":    categoryId,
      "subscription":   planName,                    // e.g. "Silver Plan"
      "package_type":   selectedPkg?.packageType  ?? "",  // ✅ PlanDataOne.packageType
      "package_value":  selectedPkg?.packageValue ?? "",  // ✅ PlanDataOne.packageValue
      "package_amount": (selectedPkg?.amount != null && selectedPkg!.amount!.isNotEmpty)
          ? selectedPkg.amount!
          : (planPrice ?? ""),  // ✅ Actual selected package amount
      "services":       servicesPayload,
      "addons":         addonsPayload,
    };

    print("FINAL PAYLOAD: ${json.encode(payload)}");



    Navigator.pushNamed(context, 
    arguments: {
      'all-data' : json.encode(payload)
    },
   Config.getSummaryScreenRouteName);

    // TODO: call your submit API with payload then navigate
  }

  // ─────────────────────────────────────────────────────
  // Live total per service card
  // ─────────────────────────────────────────────────────
  double _calcTotal(String sId) {
    final price    = double.tryParse(priceControllers[sId]?.text ?? "") ?? 0;
    final discount = double.tryParse(discountControllers[sId]?.text ?? "") ?? 0;
    if (discountTypes[sId] == "percentage") {
      return price - (price * discount / 100);
    }
    return price - discount;
  }

  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth  = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: deviceWidth * 0.05,
                    vertical: deviceHeight * 0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanRow(),
                    SizedBox(height: deviceHeight * 0.02),
                    _buildSubcategorySection(),
                    SizedBox(height: deviceHeight * 0.02),

                    // ── Services ──────────────────────────
                    if (isServicesLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF3AAD41)))
                    else if (getservices.isNotEmpty) ...[
                      const Text(
                        "Enter your service price and discount",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black54),
                      ),
                      SizedBox(height: deviceHeight * 0.01),
                      _buildServiceCards(),
                      SizedBox(height: deviceHeight * 0.02),
                    ],

                    // ── Addons ────────────────────────────
                    if (isAddonsLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF3AAD41)))
                    else if (getaddons.isNotEmpty) ...[
                      const Text(
                        "Add-ons",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                      ),
                      SizedBox(height: deviceHeight * 0.01),
                      _buildAddonCards(),
                      SizedBox(height: deviceHeight * 0.02),
                    ],

                    // ── Proceed button ────────────────────
                    if (planAdded)
                      SizedBox(
                        width: double.infinity,
                        height: deviceHeight * 0.065,
                        child: ElevatedButton(
                          onPressed: _proceedWithSubscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3AAD41),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            "Proceed with Subscription",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    SizedBox(height: deviceHeight * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SizedBox(
      height: deviceHeight * 0.28,
      width: double.infinity,
      child: Stack(children: [
        Positioned.fill(
          child: Image.network(
            UtilClass.formatImageUrl(categoryImage),
            fit: BoxFit.cover,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF3AAD41)))),
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey.shade400, size: 48),
                    const SizedBox(height: 8),
                    Text("Image not available",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ]),
            ),
          ),
        ),
        Container(color: Colors.black.withOpacity(0.2)),
        Positioned(
          left: 16,
          top: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.green)),
          ),
        ),
        Center(
          child: Text(categoryName ?? "",
              style: TextStyle(
                  fontSize: deviceWidth * 0.06,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // Plan row
  // ─────────────────────────────────────────────────────
  Widget _buildPlanRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(planName ?? "",
          style: TextStyle(
              fontSize: deviceWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
      SizedBox(height: deviceHeight * 0.015),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20)),
            child: Text("₹$planPrice",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Text(
            // ✅ PlanDataOne.package  (the label e.g. "3 Months")
            planPackages.map((p) => p.package ?? "").join(" & "),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ]),

        // Add / Added button
        GestureDetector(
          onTap: planAdded ? null : _showPackageBottomSheet,
          child: planAdded
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 28),
                  const SizedBox(width: 3),
                  Text("Added",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500)),
                ])
              : Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green)),
                  child: const Text("Add",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                ),
        ),
      ]),
    ]);
  }

  // ─────────────────────────────────────────────────────
  // Subcategory horizontal list
  // ─────────────────────────────────────────────────────
  Widget _buildSubcategorySection() {
    if (isSubCatLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF3AAD41)));
    }
    if (getsubcategories.isEmpty) {
      return const Center(
          child: Text("No subcategories available",
              style: TextStyle(fontSize: 14, color: Colors.black45)));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(getsubcategories.length, (index) {
          final SubCategory sub = getsubcategories[index];
          final bool isSelected = selectedSubIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedSubIndex      = index;
                // ✅ SubCategory.id  (not subCategoryId)
                selectedSubcategoryId = sub.id ?? "";
              });
              _getServices(selectedSubcategoryId!);
            },
            child: Container(
              margin: EdgeInsets.only(right: deviceWidth * 0.04),
              child: Column(children: [
                Container(
                  height: deviceHeight * 0.1,
                  width:  deviceWidth  * 0.25,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3AAD41)
                            : Colors.transparent,
                        width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      UtilClass.formatImageUrl(sub.subImage),
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, p) => p == null
                          ? child
                          : Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF3AAD41),
                                      strokeWidth: 2))),
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: Colors.grey.shade400, size: 28)),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  // ✅ SubCategory.subCategory  (the name field)
                  sub.subCategory ?? "",
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF3AAD41)
                          : Colors.black54,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 12),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Service cards
  // ─────────────────────────────────────────────────────
  Widget _buildServiceCards() {
    return Column(
      children: List.generate(getservices.length, (index) {
        final Services service = getservices[index];
        return StatefulBuilder(
          key: ValueKey('service_${service.id ?? index}'),
          builder: (context, setCardState) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white),
              child: Row(children: [
                // ✅ Services.serviceImage
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    // ✅ fixed missing slash between "images" and the filename
                    "https://dev.gobuddyindia.com/assets/images/${service.serviceImage ?? ''}",
                    height: deviceHeight * 0.08,
                    width:  deviceWidth  * 0.2,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        height: deviceHeight * 0.08,
                        width:  deviceWidth  * 0.2,
                        color: Colors.grey.shade100,
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400, size: 24)),
                  ),
                ),
                SizedBox(width: deviceWidth * 0.03),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Services.title
                        Text(service.title ?? "",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),

                        Row(children: [
                          Expanded(
                            child: TextField(
                              controller: priceControllers[service.id ?? index.toString()],
                              onChanged: (_) => setCardState(() {}),
                              decoration: InputDecoration(
                                hintText: "Price",
                                prefixText: "₹ ",
                                hintStyle: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: discountControllers[service.id ?? index.toString()],
                              onChanged: (_) => setCardState(() {}),
                              decoration: InputDecoration(
                                hintText: "Discount",
                                prefixText: discountTypes[service.id ?? index.toString()] == "percentage"
                                    ? "% "
                                    : "₹ ",
                                hintStyle: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                                isDense: true,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),

                        // Discount type toggle + live total
                        Row(children: [
                          _discountTypeChip(
                              service.id ?? index.toString(), "percentage", "% Off", setCardState),
                          const SizedBox(width: 8),
                          _discountTypeChip(
                              service.id ?? index.toString(), "amount", "₹ amt", setCardState),
                          const Spacer(),
                          Text(
                            "Total  ₹${_calcTotal(service.id ?? index.toString()).toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ]),
                ),
              ]),
            );
          },
        );
      }),
    );
  }

  Widget _discountTypeChip(String sId, String type, String label,
      void Function(void Function()) setCardState) {
    final bool isActive = discountTypes[sId] == type;
    return GestureDetector(
      onTap: () => setCardState(() => discountTypes[sId] = type),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3AAD41) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isActive
                  ? const Color(0xFF3AAD41)
                  : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Addon cards
  // ─────────────────────────────────────────────────────
  Widget _buildAddonCards() {
    return Column(
      children: List.generate(getaddons.length, (index) {
        final Addon addon     = getaddons[index];
        final bool isSelected = selectedAddonIndexes.contains(index);

        return StatefulBuilder(
          key: ValueKey('addon_${addon.id ?? index}'), // ✅ stable identity across rebuilds
          builder: (context, setAddonState) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3AAD41)
                        : Colors.black12,
                    width: isSelected ? 1.5 : 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    setAddonState(() {
                      isSelected
                          ? selectedAddonIndexes.remove(index)
                          : selectedAddonIndexes.add(index);
                    });
                    // ✅ no outer setState() here — keeps this card's
                    // TextField identity stable so typing works smoothly.
                    // selectedAddonIndexes is read later in
                    // _proceedWithSubscription(), so the outer tree
                    // doesn't need to rebuild on every checkbox tap.
                  },
                  child: Container(
                    height: 22,
                    width: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3AAD41)
                          : Colors.white,
                      border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3AAD41)
                              : Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Addon.addonService  (the name field)
                        Text(addon.addonService ?? "",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        if (isSelected) ...[
                          const SizedBox(height: 6),
                          TextField(
                            controller: addonPriceControllers[index],
                            decoration: InputDecoration(
                              hintText: "Enter price",
                              prefixText: "₹ ",
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ]),
                ),
              ]),
            );
          },
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────
  // Package bottom sheet
  // ─────────────────────────────────────────────────────
  void _showPackageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Select Package",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            ...List.generate(planPackages.length, (index) {
              final PlanDataOne p = planPackages[index];
              return Column(children: [
                RadioListTile<int>(
                  value: index,
                  groupValue: selectedPackageIndex,
                  activeColor: const Color(0xFF3AAD41),
                  onChanged: (val) =>
                      setModalState(() => selectedPackageIndex = val),
                  title: Text(
                    // ✅ PlanDataOne.package + PlanDataOne.amount
                    "${p.package ?? ''} — ₹${p.amount ?? '0'}",
                  ),
                  subtitle: Text(
                    // ✅ PlanDataOne.packageType + PlanDataOne.packageValue
                    "${p.packageType ?? ''}: ${p.packageValue ?? ''}",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45),
                  ),
                ),
                const Divider(),
              ]);
            }),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedPackageIndex != null
                  ? () {
                      setState(() {
                        planAdded = true;
                        if (selectedPackageIndex != null &&
                            selectedPackageIndex! < planPackages.length) {
                          final pkg = planPackages[selectedPackageIndex!];
                          if (pkg.amount != null && pkg.amount!.isNotEmpty) {
                            planPrice = pkg.amount;
                          }
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPackageIndex != null
                    ? const Color(0xFF3AAD41)
                    : Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Confirm",
                  style: TextStyle(
                      color: selectedPackageIndex != null
                          ? Colors.white
                          : Colors.black54)),
            ),
          ]),
        ),
      ),
    );
  }
}