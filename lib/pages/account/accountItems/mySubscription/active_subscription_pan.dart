import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/boras_touch_models/active_subscription_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/config.dart';
import 'package:gobuddy/utils/util_class.dart';

class MyActiveSubscriptionScreen extends StatefulWidget {
  const MyActiveSubscriptionScreen({super.key});

  @override
  State<MyActiveSubscriptionScreen> createState() =>
      _ActiveSubscriptionScreenState();
}

class _ActiveSubscriptionScreenState
    extends State<MyActiveSubscriptionScreen> {
  dynamic userData = {};
  GetProviderSubscriptionModel? _subscriptionModel;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final userDataValue = Preferences.getUserDetails();
    if (userDataValue != null) {
      userData = json.decode(userDataValue);
    }
    _getSubscriptionByProviderId();
  }


Future<void> _updatemyActiveSubscription(Data subscription) async {
  bool internet = await UtilClass.checkInternet();

  if (!internet) {
    UtilClass.showAlertDialog(
      context: context,
      message: "No Internet Connection",
    );
    return;
  }

  try {
    final body = {
      "subscription_id": subscription.subscriptionId,
      "subscription": subscription.subscription,
      "package_type": subscription.packageType,
      "package_value": subscription.packageValue,
      "package_amount": subscription.packageAmount,

      "services": subscription.services?.map((service) {
        return {
          "service_id": service.serviceId,
          "price": service.price,
          "discount": service.discount,
          "type": service.type,
        };
      }).toList(),

      // "addons": subscription.addons?.map((addon) {
      //   return {
      //     "addon_id": addon.addonId,
      //     "price": addon.price,
      //   };
      // }).toList(),
    };

    final response = await Repository.postApiRawService(
      EndPoints.updateProviderSubscription,
      body,
    );

    print("UPDATE RESPONSE => $response");

    UtilClass.showAlertDialog(
      context: context,
      message: "Subscription Updated Successfully",
    );

    _getSubscriptionByProviderId();
  } catch (e) {
    print("UPDATE ERROR => $e");

    UtilClass.showAlertDialog(
      context: context,
      message: "Failed to update subscription",
    );
  }
}
  Future<void> _getSubscriptionByProviderId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool internet = await UtilClass.checkInternet();
    if (!internet) {
      UtilClass.showAlertDialog(
          context: context, message: "No Internet Connection");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Repository.postApiService(
        EndPoints.getproviderActiveSubscriptionbyId,
        {"provider_id": userData["user_id"] ?? ""},
      );

      Map<String, dynamic> jsonResponse;
      if (response is String) {
        jsonResponse = json.decode(response);
      } else {
        jsonResponse = response;
      }

      if (jsonResponse["status"] == "valid") {
        setState(() {
          _subscriptionModel =
              GetProviderSubscriptionModel.fromJson(jsonResponse);
          _selectedTabIndex = 0;
        });
      } else {
        setState(() {
          _errorMessage =
              jsonResponse["message"] ?? "Failed to load subscriptions.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Something went wrong. Please try again.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Data> get _subscriptions => _subscriptionModel?.data ?? [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, Config.dashboardcRouteName);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, Config.dashboardcRouteName);
              }
            },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          ),
        ),
        title: const Text(
          'My Subscriptions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getSubscriptionByProviderId,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: const Color(0xFF4CAF50),
      onRefresh: _getSubscriptionByProviderId,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create New Subscription Package
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                title: const Text(
                  'Create New Subscription Package',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF4CAF50), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add,
                      color: Color(0xFF4CAF50), size: 20),
                ),
                onTap: () {

                   Navigator.pushNamed(
                      // ignore: use_build_context_synchronously
                      context,
                      Config.createPackageRouteName,
                    );
                },
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Current Subscriptions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),

            const SizedBox(height: 12),

            // Empty state
            if (_subscriptions.isEmpty)
              _buildEmptyState()
            else ...[
              // Category Tabs — dynamically built from API data
              if (_subscriptions.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_subscriptions.length, (index) {
                      final isSelected = _selectedTabIndex == index;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTabIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _subscriptions[index].category ?? 'Service',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 16),

           _SubscriptionCard(
  subscription: _subscriptions[_selectedTabIndex],
  onUpdate: () {
    _updatemyActiveSubscription(
      _subscriptions[_selectedTabIndex],
    );
  },
),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.subscriptions_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No active subscriptions found.',
              style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Subscription Card
// ─────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
 final Data subscription;
  final VoidCallback onUpdate;

const _SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.category ?? '—',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscription.subscription ?? '—'}  ( ${subscription.totalJobs} Jobs )',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (subscription.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '₹ ${subscription.formattedAmount}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _StatItem(
                  label: 'Total Jobs',
                  value: subscription.totalJobs.toString()),
              _StatItem(
                  label: 'Used',
                  value: subscription.used?.toString() ?? '0'),
              _StatItem(
                  label: 'Missed',
                  value: subscription.missed?.toString() ?? '0'),
              _StatItem(
                  label: 'Remaining',
                  value: subscription.remaining?.toString() ?? '0',
                  isLast: true),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 14),

          // Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscribed on',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subscription.formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [


                  // OutlinedButton(
                  //   onPressed: () {},
                  //   style: OutlinedButton.styleFrom(
                  //     side: BorderSide(color: Colors.grey.shade400),
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 14, vertical: 8),
                  //     shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8)),
                  //   ),
                  //   child: const Text(
                  //     'Change Prices',
                  //     style:
                  //         TextStyle(color: Colors.black87, fontSize: 13),
                  //   ),
                  // ),
                  // const SizedBox(width: 8),
                 
                 
                 
                  ElevatedButton(
                   onPressed: onUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stat Item
// ─────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _StatItem({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}