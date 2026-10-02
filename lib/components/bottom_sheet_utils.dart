// bottom_sheet_utils.dart
import 'package:flutter/material.dart';

class BottomSheetUtils {
  /// Displays a modal bottom sheet for selecting a job package plan.
  static void showJobPackageSheet({
    required BuildContext context,
    // ignore: avoid_types_as_parameter_names
    required  List<dynamic>  plansJson,
    required Function(Map<String, dynamic> selectedPackage) onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Local state management for the sheet
        int selectedTab = 0;
        String? selectedPackageId;

        return StatefulBuilder(builder: (context, setState) {
          // Get the packages for the currently selected tab
          List<dynamic> packages =  plansJson[selectedTab]["packages"];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TITLE
                const Text(
                  "Plan Update To",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                // SUBTITLE
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select job package",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),

                // TABS
                Row(
                  children: List.generate(plansJson.length, (index) {
                    bool isSelected = selectedTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Update the selected tab and reset the selected package ID
                          setState(() {
                            selectedTab = index;
                            selectedPackageId = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          // Using theme colors (or custom colors) is recommended
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            plansJson[index]["plan"],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color:
                                  isSelected ? Colors.green : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // PACKAGE LIST - Using a SingleChildScrollView to handle overflow
                // NOTE: Using a `ListView.builder` inside `Column` will require explicit height constraints.
                // Since `mainAxisSize.min` is used, the current mapping approach should work fine
                // as long as the list of packages isn't excessively long.
                ...packages.map((pkg) {
                  return Column(
                    children: [
                      RadioListTile<String>(
                        value: pkg["id"],
                        groupValue: selectedPackageId,
                        onChanged: (val) {
                          setState(() => selectedPackageId = val);
                        },
                        title: Text(
                          "${pkg["jobs"]} Jobs / ₹ ${pkg["amount"]}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),

                const SizedBox(height: 15),

                // PROCEED BUTTON
                ElevatedButton(
                  onPressed: selectedPackageId == null
                      ? null
                      : () {
                          // Find the full package map for the selected ID
                          final selectedPkg = packages.firstWhere(
                              (p) => p["id"] == selectedPackageId);

                              selectedPkg["selectedIndex"] = selectedTab;

                          Navigator.pop(context); // Close sheet
                          onSubmit(selectedPkg); // Call the callback function
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedPackageId != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "Proceed",
                    style: TextStyle(
                      color: selectedPackageId != null
                          ? Colors.white
                          : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}