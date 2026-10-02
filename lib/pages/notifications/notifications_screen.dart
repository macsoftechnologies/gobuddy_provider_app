import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/notifications_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/my_colors.dart';
import 'package:gobuddy/utils/util_class.dart';
import '../dashboard/dashboardTab_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? providerId;
  GetNotificationsModel? notificationsModel;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (providerId == null) {
      // 1. Check navigation arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['provider_id'] != null) {
        providerId = args['provider_id']?.toString();
      }

      // 2. Fall back to saved Preferences
      if (providerId == null || providerId!.isEmpty) {
        final userDataVal = Preferences.getUserDetails();
        if (userDataVal != null) {
          try {
            final parsed = jsonDecode(userDataVal);
            providerId = parsed['user_id']?.toString() ?? parsed['id']?.toString();
          } catch (_) {}
        }
      }

      debugPrint("Provider ID for notifications: $providerId");
      if (providerId != null && providerId!.isNotEmpty) {
        _getNotifications();
      }
    }
  }

  Future<void> _getNotifications() async {
    // Check internet
    final hasInternet = await UtilClass.checkInternet();
    if (!hasInternet) {
      UtilClass.showAlertDialog(
        context: context,
        message: "No Internet Connection",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Repository.postApiService(
        EndPoints.getNotifications,
        {'user_id': providerId ?? ""},
      );

      // Decode response safely
      final Map<String, dynamic> jsonResponse = response is String
          ? jsonDecode(response)
          : response as Map<String, dynamic>;

      debugPrint("API Response: $jsonResponse"); // Debug

      final model = GetNotificationsModel.fromJson(jsonResponse);

      if (model.status == "success") {
        setState(() {
          notificationsModel = model;
        });
        debugPrint("Fetched ${model.data.length} notifications");
      } else {
        debugPrint("API returned failure: ${model.message}");
        setState(() {
          notificationsModel = GetNotificationsModel(data: []);
        });
      }
    } catch (e, stack) {
      debugPrint("Error fetching notifications: $e");
      debugPrintStack(stackTrace: stack);
      setState(() {
        notificationsModel = GetNotificationsModel(data: []);
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = notificationsModel?.data ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: MyColors.appThemeLight,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text("No notifications found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _sectionTitle("Recent");
                    final data = notifications[index - 1];
                    return _notificationCard(data);
                  },
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _notificationCard(Data data) {
    final bool isNew = data.status == "new";
    final bool isCancelled = data.status == "cancelled";
    final bool isAccepted = data.status == "accepted";

    final rawAmount = data.amount?.trim() ?? "";
    final bool hasAmount = rawAmount.isNotEmpty &&
        rawAmount != "0" &&
        rawAmount != "0.0" &&
        rawAmount != "0.00" &&
        rawAmount != "null";

    final bool hasService =
        data.serviceName != null && data.serviceName!.trim().isNotEmpty;
    final bool hasLocation = data.location != null &&
        data.location!.trim().isNotEmpty &&
        data.location!.trim() != "N/A";
    final bool hasSubtitle = data.subtitle != null &&
        data.subtitle!.trim().isNotEmpty &&
        data.subtitle!.trim() != "N/A";
    final bool hasPerson = data.personName != null &&
        data.personName!.trim().isNotEmpty &&
        data.personName!.trim() != "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Time Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(data.dateTime ?? data.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          // Subtitle / Description if present
          if (hasSubtitle) ...[
            const SizedBox(height: 6),
            Text(
              data.subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ],

          // Service Name
          if (hasService) ...[
            const SizedBox(height: 6),
            Text(
              data.serviceName!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],

          // Amount (Only displayed for paid orders / when amount > 0)
          if (hasAmount) ...[
            const SizedBox(height: 6),
            Text(
              "₹ ${data.amount}",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],

          // Location
          if (hasLocation) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.location_on, data.location!),
          ],

          // Person & Booking Date
          if (hasPerson) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _infoRow(Icons.person, data.personName!)),
                if (data.dateTime != null && data.dateTime!.isNotEmpty)
                  Expanded(
                    child: _infoRow(
                      Icons.calendar_today,
                      _formatDateTime(data.dateTime),
                    ),
                  ),
              ],
            ),
          ],

          // Action buttons & Status Chips (for orders)
          if (isNew || isCancelled || isAccepted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (isNew) ...[
                  _outlineButton("Cancel", Colors.grey, () {
                    DashboardTabScreen.markOrderHandled(data.id?.toString());
                    UtilClass.showAlertDialog(context: context, message: "Order declined.");
                  }),
                  const SizedBox(width: 10),
                  _filledButton("Accept", () => _acceptOrder(data)),
                ],
                if (isCancelled)
                  _statusChip("Cancelled", Colors.red.shade100, Colors.red),
                if (isAccepted)
                  _statusChip("Accepted", Colors.green.shade100, Colors.green),
              ],
            ),
          ],
        ],
      ),
    );
  }


  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return "Now";
    try {
      final dt = DateTime.parse(dateTime);
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateTime;
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        )
      ],
    );
  }

  Future<void> _acceptOrder(Data data) async {
    final orderId = data.id?.toString().trim();
    if (orderId == null || orderId.isEmpty) {
      UtilClass.showAlertDialog(context: context, message: "Order identifier missing");
      return;
    }

    final hasInternet = await UtilClass.checkInternet();
    if (!hasInternet) {
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    UtilClass.showProgress(context: context);
    try {
      final response = await Repository.postApiService(
        EndPoints.orderaccept,
        {
          "job_calender_id": orderId,
          "provider_id": providerId ?? "",
        },
      );
      UtilClass.hideProgress();

      dynamic parsed = response;
      if (response is String) {
        try {
          parsed = jsonDecode(response);
        } catch (_) {}
      }

      if (parsed != null && (parsed["status"] == "valid" || parsed["status"] == true || parsed["status"] == "success")) {
        DashboardTabScreen.markOrderHandled(orderId);
        UtilClass.showAlertDialog(
          context: context,
          message: parsed["message"] ?? "Order accepted successfully!",
        );
        _getNotifications();
      } else {
        UtilClass.showAlertDialog(
          context: context,
          message: parsed?["message"] ?? "Failed to accept order",
        );
      }
    } catch (e) {
      UtilClass.hideProgress();
      UtilClass.showAlertDialog(context: context, message: "Network error. Please try again.");
    }
  }

  Widget _filledButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Text(text),
      ),
    );
  }

  Widget _outlineButton(String text, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: color),
      ),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }

  Widget _statusChip(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}