class GetProviderSubscriptionModel {
  String? status;
  String? message;
  List<Data>? data;

  GetProviderSubscriptionModel({this.status, this.message, this.data});

  factory GetProviderSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return GetProviderSubscriptionModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<Data>.from(json['data'].map((x) => Data.fromJson(x)))
          : [],
    );
  }
}

class Data {
  String? subscriptionId;
  String? providerId;
  String? categoryId;
  String? subscription;
  String? packageType;
  String? packageValue;
  String? packageAmount;
  int? used;
  int? missed;
  int? remaining;
  String? subscribedon;
  String? category;
  String? statusText;
  PackageDetails? packageDetails;
  List<Services>? services;

  Data({
    this.subscriptionId,
    this.providerId,
    this.categoryId,
    this.subscription,
    this.packageType,
    this.packageValue,
    this.packageAmount,
    this.used,
    this.missed,
    this.remaining,
    this.subscribedon,
    this.category,
    this.statusText,
    this.packageDetails,
    this.services,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      subscriptionId: json['subscription_id']?.toString(),
      providerId: json['provider_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      subscription: json['subscription']?.toString(),
      packageType: json['package_type']?.toString(),
      packageValue: json['package_value']?.toString() ?? json['jobs']?.toString() ?? '0',
      packageAmount: json['package_amount']?.toString() ?? json['package']?.toString() ?? json['amount']?.toString() ?? '0',
      used: json['used'] is int ? json['used'] : int.tryParse(json['used']?.toString() ?? '0') ?? 0,
      missed: json['missed'] is int ? json['missed'] : int.tryParse(json['missed']?.toString() ?? '0') ?? 0,
      remaining: json['remaining'] is int ? json['remaining'] : int.tryParse(json['remaining']?.toString() ?? '0') ?? 0,
      subscribedon: json['subscribedon']?.toString(),
      category: json['category']?.toString(),
      statusText: json['status_text']?.toString() ?? ((json['status'] == 1 || json['status'] == '1') ? 'Active' : 'Inactive'),
      packageDetails: json['package_details'] != null
          ? PackageDetails.fromJson(json['package_details'])
          : null,
      services: json['services'] != null
          ? List<Services>.from(json['services'].map((x) => Services.fromJson(x)))
          : [],
    );
  }

  bool get isActive => statusText?.toLowerCase() == 'active';

  int get totalJobs => int.tryParse(packageValue ?? '0') ?? 0;

  String get formattedAmount {
    final amount = double.tryParse(packageAmount ?? '0') ?? 0;
    return amount.toStringAsFixed(0);
  }

  String get formattedDate {
    if (subscribedon == null) return '';
    try {
      final dt = DateTime.parse(subscribedon!);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return subscribedon!;
    }
  }
}

class PackageDetails {
  String? type;
  String? value;
  String? amount;

  PackageDetails({this.type, this.value, this.amount});

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    return PackageDetails(
      type: json['type'],
      value: json['value'],
      amount: json['amount'],
    );
  }
}

class Services {
  String? subscriptionServiceId;
  String? subCategoryId;
  String? serviceId;
  String? price;
  String? discount;
  String? type;
  String? subscriptionId;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? providerId;
  int? usedJobs;
  int? missedJobs;

  Services({
    this.subscriptionServiceId,
    this.subCategoryId,
    this.serviceId,
    this.price,
    this.discount,
    this.type,
    this.subscriptionId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.providerId,
    this.usedJobs,
    this.missedJobs,
  });

  factory Services.fromJson(Map<String, dynamic> json) {
    return Services(
      subscriptionServiceId: json['subscription_service_id'],
      subCategoryId: json['sub_category_id'],
      serviceId: json['service_id'],
      price: json['price'],
      discount: json['discount'],
      type: json['type'],
      subscriptionId: json['subscription_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      providerId: json['provider_id'],
      usedJobs: json['used_jobs'] is int
          ? json['used_jobs']
          : int.tryParse(json['used_jobs'].toString()) ?? 0,
      missedJobs: json['missed_jobs'] is int
          ? json['missed_jobs']
          : int.tryParse(json['missed_jobs'].toString()) ?? 0,
    );
  }
}