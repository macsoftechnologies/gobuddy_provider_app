import 'dart:async';
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
  String selectedTab = "Open";
  dynamic userData = {};
  List<dynamic> orders = [];
  dynamic selectType = "open";
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab ?? "Open";
    var userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    callOrdersPI(selectedTab);
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && selectedTab.toLowerCase() == "open") {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
          if (parsed["orders"] is List) {
            return List<dynamic>.from(parsed["orders"]);
          }
          if (parsed["data"] is List) {
            return List<dynamic>.from(parsed["data"]);
          }
        }
        return null;
      }

      bool isOrderCancelled(dynamic o) {
        if (o == null) return false;
        final status = (o["status"] ?? o["order_status"] ?? "").toString().toLowerCase().trim();
        final orderStatus = (o["order_status"] ?? "").toString().trim();
        return status == "cancelled" ||
            status == "canceled" ||
            status == "cancel" ||
            status == "rejected" ||
            status == "reject" ||
            status == "declined" ||
            orderStatus == "3" ||
            orderStatus == "4" ||
            orderStatus == "5";
      }

      bool isOrderCompleted(dynamic o) {
        if (o == null) return false;
        final status = (o["status"] ?? o["order_status"] ?? "").toString().toLowerCase().trim();
        final orderStatus = (o["order_status"] ?? "").toString().trim();
        return status == "completed" || 
            status == "complete" || 
            status == "delivered" ||
            status == "finished" ||
            status == "done" ||
            orderStatus == "2";
      }

      bool isOrderAccepted(dynamic o) {
        if (o is! Map) return false;
        final id = (o["id"] ?? "").toString().trim();
        final jobCalId = (o["job_calender_id"] ?? "").toString().trim();
        final ordTxn = (o["order_txn"] ?? o["order_id"] ?? "").toString().trim();
        final status = (o["status"] ?? o["order_status"] ?? "").toString().toLowerCase().trim();

        // If backend explicitly sets status to accepted or started
        if (status == "accepted" ||
            status == "started" ||
            status == "in_progress" ||
            status == "ongoing") {
          return true;
        }
        if (o["is_accepted"] == 1 || o["is_accepted"] == "1" || o["is_accepted"] == true) {
          return true;
        }

        // Check persistent local preferences
        if (Preferences.isOrderAcceptedLocally(id) ||
            Preferences.isOrderAcceptedLocally(jobCalId) ||
            Preferences.isOrderAcceptedLocally(ordTxn)) {
          return true;
        }

        return false;
      }

      bool belongsToProvider(dynamic o) {
        if (o is! Map) return false;
        final pId = (o["provider_id"] ?? o["assigned_to"] ?? "").toString().trim();
        if (pId.isNotEmpty && pId != "0" && pId != "null") {
          return pId == userId;
        }
        final uId = (o["user_id"] ?? "").toString().trim();
        return uId.isEmpty || uId == userId;
      }

      bool isOrderOpen(dynamic o) {
        if (isOrderCancelled(o) || isOrderCompleted(o)) return false;
        // If the order has already been accepted, it moves to Pending tab!
        if (isOrderAccepted(o)) return false;
        return true;
      }

      bool isOrderPending(dynamic o) {
        if (isOrderCancelled(o) || isOrderCompleted(o)) return false;
        // Pending orders MUST be accepted and belong to this provider
        return isOrderAccepted(o) && belongsToProvider(o);
      }

      if (tabKey == "open") {
        // Open orders: Broadcast or newly received orders waiting for provider to Accept
        // 1. Fetch from openOrders endpoint
        try {
          final res = await Repository.getApiService(EndPoints.openOrders);
          dynamic parsed = res is String ? json.decode(res) : res;
          final list = extractOrders(parsed);
          if (list != null && list.isNotEmpty) {
            for (var o in list) {
              if (isOrderOpen(o)) fetchedOrders.add(o);
            }
          }
        } catch (_) {}

        // 2. Also fetch newly assigned orders for this provider (which arrive via pendingOrders)
        try {
          final res = await Repository.postApiService(EndPoints.pendingOrders, {
            "provider_id": userId,
          });
          dynamic parsed = res is String ? json.decode(res) : res;
          final list = extractOrders(parsed);
          if (list != null && list.isNotEmpty) {
            for (var o in list) {
              if (isOrderOpen(o)) fetchedOrders.add(o);
            }
          }
        } catch (_) {}

        // 3. Fallback to getOrders API
        if (fetchedOrders.isEmpty) {
          try {
            final res = await Repository.postApiService(EndPoints.getOrders, {
              "user_id": userId,
              "status": "pending",
            });
            dynamic parsed = res is String ? json.decode(res) : res;
            final list = extractOrders(parsed);
            if (list != null && list.isNotEmpty) {
              for (var o in list) {
                if (isOrderOpen(o)) fetchedOrders.add(o);
              }
            }
          } catch (_) {}
        }

        // Orders will be cleanly consolidated below for all tabs
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
            fetchedOrders = list.where((o) => isOrderCancelled(o) && belongsToProvider(o)).toList();
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
              fetchedOrders = list.where((o) => isOrderCancelled(o) && belongsToProvider(o)).toList();
            }
          } catch (_) {}
        }
      }

      final consolidatedOrders = _consolidateOrders(fetchedOrders);
      if (mounted) {
        setState(() {
          selectType = tabKey;
          orders = consolidatedOrders;
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

  void callAcceptAPI(dynamic id, [dynamic order]) async {
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
            final idStr = id?.toString().trim() ?? "";
            if (idStr.isNotEmpty) {
              DashboardTabScreen.markOrderHandled(idStr);
              Preferences.addAcceptedOrderId(idStr);
            }
            if (order is Map) {
              final ordId = (order["id"] ?? "").toString().trim();
              final calId = (order["job_calender_id"] ?? "").toString().trim();
              final txnId = (order["order_txn"] ?? order["order_id"] ?? "").toString().trim();
              if (ordId.isNotEmpty) {
                DashboardTabScreen.markOrderHandled(ordId);
                Preferences.addAcceptedOrderId(ordId);
              }
              if (calId.isNotEmpty) {
                DashboardTabScreen.markOrderHandled(calId);
                Preferences.addAcceptedOrderId(calId);
              }
              if (txnId.isNotEmpty) {
                DashboardTabScreen.markOrderHandled(txnId);
                Preferences.addAcceptedOrderId(txnId);
              }
            }
            UtilClass.showAlertDialog(
              context: context,
              message: "Order accepted successfully",
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
                  children: ["Open", "Pending", "Completed", "Canceled"].map((
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

  List<dynamic> _consolidateOrders(List<dynamic> rawList) {
    if (rawList.isEmpty) return rawList;
    final Map<String, Map<String, dynamic>> groups = {};
    final List<String> groupKeys = [];

    for (var item in rawList) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      // Determine unique booking key (job_calender_id or order_txn)
      final calId = (map["job_calender_id"] ?? "").toString().trim();
      final txn = (map["order_txn"] ?? map["order_id"] ?? "").toString().trim();
      final id = (map["id"] ?? "").toString().trim();

      String key = "";
      if (calId.isNotEmpty && calId != "0" && calId != "null") {
        key = "cal_$calId";
      } else if (txn.isNotEmpty && txn != "0" && txn != "null") {
        key = "txn_$txn";
      } else if (id.isNotEmpty) {
        key = "id_$id";
      } else {
        key = "idx_${groupKeys.length}";
      }

      final sName = (map["service_name"] ?? map["title"] ?? map["service"] ?? "").toString().trim();

      if (!groups.containsKey(key)) {
        groups[key] = map;
        groupKeys.add(key);
        map["_grouped_service_names"] = sName.isNotEmpty ? <String>[sName] : <String>[];
        map["_grouped_items"] = <Map<String, dynamic>>[map];
      } else {
        final existing = groups[key]!;
        final names = (existing["_grouped_service_names"] as List<String>?) ?? <String>[];
        if (sName.isNotEmpty && !names.contains(sName)) {
          names.add(sName);
          existing["_grouped_service_names"] = names;
        }
        final items = (existing["_grouped_items"] as List<Map<String, dynamic>>?) ?? <Map<String, dynamic>>[];
        items.add(map);
        existing["_grouped_items"] = items;

        // Sum prices if total_amount is not present on the booking
        final p1 = double.tryParse((existing["grand_total"] ?? existing["price"] ?? '0').toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
        final p2 = double.tryParse((map["grand_total"] ?? map["price"] ?? '0').toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
        final totalAmt = double.tryParse((existing["total_amount"] ?? '0').toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
        if (totalAmt <= 0 && p2 > 0) {
          existing["grand_total"] = (p1 + p2).toStringAsFixed(2);
        }
      }
    }

    return groupKeys.map((k) => groups[k]!).toList();
  }

  String _getServiceName(dynamic order) {
    if (order == null) return "Service";
    if (order is Map && order["_grouped_service_names"] is List) {
      final names = (order["_grouped_service_names"] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (names.length == 2) {
        return "${names[0]} & ${names[1]}";
      } else if (names.length > 2) {
        return "${names[0]} (+${names.length - 1} more)";
      } else if (names.length == 1) {
        return names[0];
      }
    }
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

  double _parseOrderNum(dynamic val) {
    if (val == null) return 0.0;
    final s = val.toString().replaceAll("₹", "").replaceAll(",", "").trim();
    return double.tryParse(s) ?? 0.0;
  }

  double _getCalculatedTotalBill(dynamic order) {
    if (order == null) return 0.0;
    return _getDoorstepCollectedAmount(order);
  }

  double _getDoorstepCollectedAmount(dynamic order) {
    if (order == null) return 0.0;
    final doorstepAmt = _parseOrderNum(order["doorstep_amount"]);
    final platformFee = _parseOrderNum(order["platform_fee"]);
    final totalAmt = _parseOrderNum(order["total_amount"]);

    if (doorstepAmt > 0 && (platformFee == 0 || doorstepAmt != platformFee)) {
      return doorstepAmt;
    }

    final subTotal = _parseOrderNum(order["sub_total"] ?? order["price"]);
    final travel = _parseOrderNum(order["travelling_charges"] ?? order["travelingCharge"]);
    double extraTotal = _parseOrderNum(order["extra_charges_total"] ?? order["add_extra_charges"]);
    if (extraTotal == 0.0 && order["extra_charges"] is List) {
      for (final ec in order["extra_charges"]) {
        if (ec is Map) {
          extraTotal += _parseOrderNum(ec["extra_charge_amount"] ?? ec["amount"]);
        }
      }
    }

    if (totalAmt > 0 && totalAmt != platformFee) {
      return totalAmt;
    }

    if (subTotal > 0) {
      return subTotal + extraTotal + travel;
    }

    final grandTotal = _parseOrderNum(order["grand_total"] ?? order["total_order_amount"]);
    if (grandTotal > 0) {
      if (platformFee > 0 && grandTotal > platformFee) {
        return grandTotal - platformFee;
      }
      return grandTotal;
    }

    return 0.0;
  }

  String _getOrderAmount(dynamic order) {
    if (order == null) return "₹ 0";
    if (order is Map && order["_grouped_items"] is List && (order["_grouped_items"] as List).length > 1) {
      final total = _getDoorstepCollectedAmount(order);
      if (total > 0) {
        return "₹ ${total.toStringAsFixed(0)}";
      }
      final items = order["_grouped_items"] as List;
      double sum = 0.0;
      for (var it in items) {
        final p = double.tryParse((it["grand_total"] ?? it["price"] ?? it["total_amount"] ?? "0").toString().replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;
        sum += p;
      }
      if (sum > 0) {
        return "₹ ${sum.toStringAsFixed(0)}";
      }
    }
    final total = _getDoorstepCollectedAmount(order);
    if (total > 0) {
      return "₹ ${total.toStringAsFixed(0)}";
    }
    for (final key in [
      "doorstep_amount",
      "sub_total",
      "total_amount",
      "amount",
      "price",
      "total_order_amount",
      "grand_total",
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
    if (order is! Map) return "Expired";

    final status = (order["status"] ?? order["order_status"] ?? "").toString().toLowerCase().trim();
    if (status.contains("expire") || status == "3" || status == "cancelled" || status == "canceled") {
      return "Expired";
    }

    final createdAtStr = (order["created_at"] ?? order["date_time"] ?? order["order_date"] ?? "").toString().trim();
    if (createdAtStr.isNotEmpty) {
      try {
        DateTime? createdTime = DateTime.tryParse(createdAtStr);
        if (createdTime == null) {
          final parts = createdAtStr.replaceAll("T", " ").split(" ");
          if (parts.length >= 2) {
            final dateParts = parts[0].split("-");
            final timeParts = parts[1].split(":");
            if (dateParts.length == 3 && timeParts.length >= 2) {
              createdTime = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
                int.parse(timeParts[0]),
                int.parse(timeParts[1]),
                timeParts.length > 2 ? int.parse(timeParts[2].split(".")[0]) : 0,
              );
            }
          }
        }

        if (createdTime != null) {
          final now = DateTime.now();
          const int windowSeconds = 60 * 60; // 60 minutes acceptance window
          final elapsedSeconds = now.difference(createdTime).inSeconds;
          final remainingSeconds = windowSeconds - elapsedSeconds;

          if (remainingSeconds <= 0) {
            return "Expired";
          }

          final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
          final secs = (remainingSeconds % 60).toString().padLeft(2, '0');
          return "$mins:$secs";
        }
      } catch (_) {}
    }

    final timerVal = order["timer"] ?? order["countdown"] ?? order["remaining_time"];
    if (timerVal != null && timerVal.toString().trim().isNotEmpty && timerVal.toString().trim() != "59:15") {
      return timerVal.toString().trim();
    }

    return "Expired";
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getServiceCategory(order),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFC8E6C9)),
                            ),
                            child: Text(
                              "Qty: ${order["quantity"] ?? order["qty"] ?? 1}",
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                        order,
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

    // 4. Pending Tab: Accepted order waiting to start, or already started waiting to continue
    final id = (order["id"] ?? "").toString().trim();
    final jobCalId = (order["job_calender_id"] ?? "").toString().trim();
    final ordTxn = (order["order_txn"] ?? "").toString().trim();
    final bool isStarted = status == "started" ||
        status == "in_progress" ||
        status == "ongoing" ||
        Preferences.isOrderStartedLocally(id) ||
        Preferences.isOrderStartedLocally(jobCalId) ||
        Preferences.isOrderStartedLocally(ordTxn);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: isStarted
              ? () {
                  Navigator.of(context)
                      .pushNamed(
                        Config.orderDetailsRouteName,
                        arguments: Map<String, dynamic>.from(order),
                      )
                      .then((_) {
                        callOrdersPI(selectedTab);
                      });
                }
              : () => _startOrder(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: isStarted ? const Color(0xFF2E7D32) : const Color(0xFFE8EAF6),
            foregroundColor: isStarted ? Colors.white : const Color(0xFF4A409A),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isStarted) ...[
                const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                isStarted ? "Continue" : "Start",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isStarted ? Colors.white : const Color(0xFF4A409A),
                ),
              ),
            ],
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
      final ordId = (order["id"] ?? "").toString().trim();
      final calId = (order["job_calender_id"] ?? "").toString().trim();
      final txnId = (order["order_txn"] ?? order["order_id"] ?? "").toString().trim();
      if (orderId != null) Preferences.addStartedOrderId(orderId.toString().trim());
      if (ordId.isNotEmpty) Preferences.addStartedOrderId(ordId);
      if (calId.isNotEmpty) Preferences.addStartedOrderId(calId);
      if (txnId.isNotEmpty) Preferences.addStartedOrderId(txnId);

      try {
        await Repository.postApiService(EndPoints.orderaccept, {
          "job_calender_id": orderId.toString(),
          "provider_id": (userData["user_id"] ?? userData["id"] ?? "")
              .toString(),
          "status": "started",
        });
      } catch (_) {}

      if (mounted) {
        setState(() {}); // refresh button to 'Continue'
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
