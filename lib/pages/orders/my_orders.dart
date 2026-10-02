// ignore_for_file: use_build_context_synchronously, avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import '../../utils/config.dart';
import '../dashboard/dashboardTab_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String? initialTab;
  const MyOrdersScreen({super.key, this.onBackToHome, this.initialTab});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String selectedTab = "Pending";
  dynamic userData = {};
  List<dynamic> orders = [];
  dynamic selectType = "pending";

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab ?? "Pending";
    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    callOrdersPI(selectedTab);
  }

  void callOrdersPI(tab) async {
    var internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
      return;
    }

    UtilClass.showProgress(context: context);
    try {
      final tabKey = tab.toString().toLowerCase();
      List<dynamic> fetchedOrders = [];
      final userId = userData["user_id"]?.toString() ?? "";

      List<dynamic>? extractOrders(dynamic parsed) {
        if (parsed is Map) {
          if (parsed["orders"] is List)
            return List<dynamic>.from(parsed["orders"]);
          if (parsed["data"] is List) return List<dynamic>.from(parsed["data"]);
        }
        return null;
      }

      bool isOrderCancelled(dynamic o) {
        final status = (o["status"] ?? "").toString().toLowerCase().trim();
        final orderStatus = (o["order_status"] ?? "").toString().trim();
        return status == "cancelled" ||
            status == "canceled" ||
            orderStatus == "3";
      }

      bool isOrderCompleted(dynamic o) {
        final status = (o["status"] ?? "").toString().toLowerCase().trim();
        final orderStatus = (o["order_status"] ?? "").toString().trim();
        return status == "completed" || orderStatus == "2";
      }

      bool isOrderPending(dynamic o) {
        if (isOrderCancelled(o) || isOrderCompleted(o)) return false;
        
        // Only accepted orders (assigned to this provider) should be in Pending
        final pId = (o["provider_id"] ?? o["assigned_to"] ?? "").toString().trim();
        if (pId == "0" || pId.isEmpty || pId == "null") {
          return false; // Not accepted by anyone yet (Open)
        }
        if (pId != userId) {
          return false; // Accepted by someone else
        }
        return true;
      }

      if (tabKey == "open") {
        // Open orders: Broadcast orders available for provider to Accept (strictly exclude cancelled and completed)
        try {
          final res = await Repository.getApiService(EndPoints.openOrders);
          dynamic parsed = res is String ? json.decode(res) : res;
          final list = extractOrders(parsed);
          if (list != null && list.isNotEmpty) {
            fetchedOrders = list
                .where((o) => !isOrderCancelled(o) && !isOrderCompleted(o))
                .toList();
          }
        } catch (_) {}

        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.postApiService(EndPoints.getOrders, {
              "user_id": userId,
              "status": "open",
            });
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              fetchedOrders = list
                  .where((o) => !isOrderCancelled(o) && !isOrderCompleted(o) && !isOrderPending(o))
                  .toList();
            }
          } catch (_) {}
        }
      } else if (tabKey == "pending") {
        // Pending orders: Accepted orders assigned to this provider, waiting to Start
        try {
          final res = await Repository.postApiService(EndPoints.pendingOrders, {
            "provider_id": userId,
          });
          dynamic parsed = res is String ? json.decode(res) : res;
          final list = extractOrders(parsed);
          if (list != null && list.isNotEmpty) {
            fetchedOrders = list
                .where((o) => isOrderPending(o))
                .toList();
          }
        } catch (_) {}

        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.postApiService(EndPoints.getOrders, {
              "user_id": userId,
              "status": "pending",
            });
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              fetchedOrders = list
                  .where((o) => isOrderPending(o))
                  .toList();
            }
          } catch (_) {}
        }

        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.postApiService(EndPoints.getOrders, {
              "user_id": userId,
              "status": "accepted",
            });
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              fetchedOrders = list
                  .where((o) => isOrderPending(o))
                  .toList();
            }
          } catch (_) {}
        }
      } else if (tabKey == "completed") {
        try {
          final res = await Repository.postApiService(
            EndPoints.completeOrders,
            {"provider_id": userId},
          );
          dynamic parsed = res is String ? json.decode(res) : res;
          final list = extractOrders(parsed);
          if (list != null && list.isNotEmpty) {
            fetchedOrders = list.where((o) => isOrderCompleted(o)).toList();
          }
        } catch (_) {}

        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.postApiService(EndPoints.getOrders, {
              "user_id": userId,
              "status": "completed",
            });
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              fetchedOrders = list.where((o) => isOrderCompleted(o)).toList();
            }
          } catch (_) {}
        }
      } else if (tabKey == "cancelled" || tabKey == "canceled") {
        try {
          final res = await Repository.postApiService(
            EndPoints.cancelOrdersList,
            {"provider_id": userId},
          );
          dynamic parsed = res is String ? json.decode(res) : res;
          final list = extractOrders(parsed);
          if (list != null && list.isNotEmpty) {
            fetchedOrders = list.where((o) => isOrderCancelled(o)).toList();
          }
        } catch (_) {}

        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.postApiService(EndPoints.getOrders, {
              "user_id": userId,
              "status": "cancelled",
            });
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              fetchedOrders = list.where((o) => isOrderCancelled(o)).toList();
            }
          } catch (_) {}
        }

        // Also check if openorders has cancelled orders so they show under Canceled tab
        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.getApiService(EndPoints.openOrders);
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              fetchedOrders = list.where((o) => isOrderCancelled(o)).toList();
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          selectType = tabKey;
          orders = fetchedOrders;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          selectType = tab.toString().toLowerCase();
          orders = [];
        });
      }
    } finally {
      UtilClass.hideProgress();
    }
  }

  void callAcceptAPI(dynamic id) async {
    var internet = await UtilClass.checkInternet();
    if (internet) {
      UtilClass.showProgress(context: context);
      await Repository.postApiService(EndPoints.orderaccept, {
        "job_calender_id": id,
        "provider_id": userData["user_id"] ?? "",
      }).then((value) async {
        UtilClass.hideProgress();

        dynamic parsed;
        try {
          parsed = value is String ? json.decode(value) : value;
        } catch (e) {
          parsed = value;
        }

        try {
          if (parsed != null &&
              (parsed["status"] == "valid" ||
                  parsed["status"] == true ||
                  parsed["status"] == "success")) {
            DashboardTabScreen.markOrderHandled(id?.toString());
            UtilClass.showAlertDialog(
              context: context,
              message: parsed["message"] ?? "Order accepted successfully",
            );
            // Move to Pending tab where provider can tap Start
            setState(() {
              selectedTab = "Pending";
            });
            callOrdersPI("Pending");
          } else {
            UtilClass.showAlertDialog(
              context: context,
              message: parsed?["message"] ?? "Failed to accept order",
            );
          }
        } catch (_) {}
      });
    } else {
      UtilClass.showAlertDialog(context: context, message: Config.kNoInternet);
    }
  }

  void _cancelOrder(dynamic order) async {
    final orderId = order["id"] ?? order["job_calender_id"];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Decline Order",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to decline this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Decline"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      UtilClass.showProgress(context: context);
      try {
        await Repository.postApiService(EndPoints.cancelOrders, {
          "job_calender_id": orderId.toString(),
          "cancel_reason": "Declined by provider",
        });
      } catch (_) {}
      UtilClass.hideProgress();
      callOrdersPI(selectedTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.onBackToHome != null) {
          widget.onBackToHome!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, Config.dashboardcRouteName);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(deviceWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.onBackToHome != null) {
                          widget.onBackToHome!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            Config.dashboardcRouteName,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A651),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: deviceWidth * 0.04),
                    const Text(
                      "My orders",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: deviceHeight * 0.02),

                // Tabs matching Figma design
                Row(
                  children: ["Pending", "Open", "Completed", "Canceled"].map((
                    tab,
                  ) {
                    final isSelected =
                        selectedTab.toLowerCase() == tab.toLowerCase() ||
                        (tab == "Canceled" &&
                            selectedTab.toLowerCase() == "cancelled");
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTab = tab;
                          });
                          callOrdersPI(tab);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00A651)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00A651)
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: deviceHeight * 0.02),

                // Orders List
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Text(
                            "No orders found",
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _buildOrderCard(order, deviceWidth);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getServiceName(dynamic order) {
    if (order == null) return "Service";
    if (order["service_name"] != null &&
        order["service_name"].toString().trim().isNotEmpty) {
      return order["service_name"].toString().trim();
    }
    if (order["order_service_name"] != null &&
        order["order_service_name"].toString().trim().isNotEmpty) {
      return order["order_service_name"].toString().trim();
    }
    if (order["title"] != null && order["title"].toString().trim().isNotEmpty) {
      return order["title"].toString().trim();
    }
    if (order["service"] != null &&
        order["service"].toString().trim().isNotEmpty) {
      return order["service"].toString().trim();
    }
    if (order["category_name"] != null &&
        order["category_name"].toString().trim().isNotEmpty) {
      return order["category_name"].toString().trim();
    }
    if (order["working_category"] != null &&
        order["working_category"].toString().trim().isNotEmpty) {
      return order["working_category"].toString().trim();
    }
    if (order["services"] is List && (order["services"] as List).isNotEmpty) {
      final first = (order["services"] as List).first;
      if (first is Map &&
          first["service_name"] != null &&
          first["service_name"].toString().trim().isNotEmpty) {
        return first["service_name"].toString().trim();
      }
    }
    return "Service";
  }

  String _getServiceCategory(dynamic order) {
    if (order == null) return "General Service";
    for (final key in [
      "sub_category_name",
      "category_name",
      "sub_category",
      "category",
      "working_category",
    ]) {
      final val = order[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return "General Service";
  }

  String _getOrderAddress(dynamic order) {
    if (order == null) return "Address not specified";
    if (order["customer"] is Map &&
        order["customer"]["address"] != null &&
        order["customer"]["address"].toString().trim().isNotEmpty) {
      return order["customer"]["address"].toString().trim();
    }
    if (order["user"] is Map &&
        order["user"]["address"] != null &&
        order["user"]["address"].toString().trim().isNotEmpty) {
      return order["user"]["address"].toString().trim();
    }
    for (final key in [
      "customer_address",
      "address",
      "landmark",
      "location",
      "street",
      "city",
    ]) {
      final val = order[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return "Visakhapatnam";
  }

  String _getOrderSchedule(dynamic order) {
    if (order == null) return "Today";
    final date =
        (order["service_date"] ??
                order["schedule_date"] ??
                order["booking_date"] ??
                order["date"] ??
                "")
            .toString()
            .trim();
    final time =
        (order["service_time"] ?? order["schedule_time"] ?? order["time"] ?? "")
            .toString()
            .trim();
    if (date.isNotEmpty && time.isNotEmpty) {
      return "$date  $time";
    }
    if (date.isNotEmpty) return date;
    if (time.isNotEmpty) return time;
    final created = order["created_at"]?.toString().trim() ?? "";
    return created.isNotEmpty ? created : "10/8/2024 12:00 AM";
  }

  String _getOrderAmount(dynamic order) {
    if (order == null) return "₹ 0";
    for (final key in [
      "total_amount",
      "amount",
      "sub_total",
      "grand_total",
      "price",
      "order_amount",
      "package",
    ]) {
      final val = order[key];
      if (val != null &&
          val.toString().trim().isNotEmpty &&
          val.toString().trim() != "0") {
        return "₹ ${val.toString().trim()}";
      }
    }
    return "₹ 399";
  }

  String _getOrderImage(dynamic order) {
    if (order == null) return "";
    for (final key in [
      "service_image",
      "image",
      "category_image",
      "sub_category_image",
      "profile",
    ]) {
      final val = order[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return UtilClass.formatProfileImageUrl(val.toString().trim());
      }
    }
    return "";
  }

  String _getOrderTimer(dynamic order) {
    final timerVal =
        order["timer"] ?? order["countdown"] ?? order["remaining_time"];
    if (timerVal != null && timerVal.toString().trim().isNotEmpty) {
      return timerVal.toString().trim();
    }
    final status = (order["status"] ?? "").toString().toLowerCase();
    if (status.contains("expire")) return "Expired";
    return "59:15";
  }

  Widget _buildOrderCard(dynamic order, double deviceWidth) {
    final imgUrl = _getOrderImage(order);

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .pushNamed(
              Config.orderDetailsRouteName,
              arguments: Map<String, dynamic>.from(order),
            )
            .then((_) {
              callOrdersPI(selectedTab);
            });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Image + Details (Faithful to Figma)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 65,
                    height: 65,
                    color: Colors.grey.shade100,
                    child: imgUrl.isNotEmpty
                        ? Image.network(
                            imgUrl,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/acservice.png',
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/images/acservice.png',
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceName(order),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getServiceCategory(order),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getOrderAddress(order),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getOrderSchedule(order),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Action & Price Row strictly matching Figma tabs
            _buildOrderActionUI(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActionUI(dynamic order) {
    final currentTab = selectedTab.toLowerCase();
    final status = (order["status"] ?? order["order_status"] ?? "")
        .toString()
        .toLowerCase()
        .trim();

    // 1. Completed Tab or status
    if (currentTab == "completed" || status == "completed") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Completed",
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _getOrderAmount(order),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      );
    }

    // 2. Canceled Tab or status
    if (currentTab == "cancelled" ||
        currentTab == "canceled" ||
        status == "cancelled" ||
        status == "canceled") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Cancelled",
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _getOrderAmount(order),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      );
    }

    // 3. Open Tab: Figma shows Cancel + Accept buttons & Price + Timer
    if (currentTab == "open" && status != "accepted" && status != "started") {
      final timerText = _getOrderTimer(order);
      final isExpired = timerText.toLowerCase().contains("expire");

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => _cancelOrder(order),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isExpired
                    ? null
                    : () => callAcceptAPI(
                        order["id"] ?? order["job_calender_id"],
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpired
                      ? Colors.grey.shade400
                      : const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Accept",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getOrderAmount(order),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: isExpired ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    timerText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isExpired ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // 4. Pending Tab (Figma Screen 1): Accepted order waiting to start
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _startOrder(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8EAF6),
            foregroundColor: const Color(0xFF4A409A),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Start",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A409A),
            ),
          ),
        ),
        Text(
          _getOrderAmount(order),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _startOrder(dynamic order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.directions_car, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text(
              "Start Job Travelling",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "Are you starting your journey to the customer site? The customer will be notified that you are on your way.",
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Not Yet", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, I'm on the way"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final orderId = order["job_calender_id"] ?? order["id"];
      try {
        await Repository.postApiService(EndPoints.orderaccept, {
          "job_calender_id": orderId.toString(),
          "provider_id": (userData["user_id"] ?? userData["id"] ?? "")
              .toString(),
          "status": "started",
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Customer has been notified that you are travelling to their location.",
            ),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    }

    if (mounted) {
      Navigator.of(context)
          .pushNamed(
            Config.orderDetailsRouteName,
            arguments: Map<String, dynamic>.from(order),
          )
          .then((_) {
            callOrdersPI(selectedTab);
          });
    }
  }
}
