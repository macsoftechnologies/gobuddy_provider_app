class GetProviderSubscriptionModel {
  final String? status;
  final String? message;
  final List<Data>? data;

  GetProviderSubscriptionModel({
    this.status,
    this.message,
    this.data,
  });

  factory GetProviderSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return GetProviderSubscriptionModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => Data.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data?.map((e) => e.toJson()).toList(),
      };
}

class Data {
  final String? subscriptionId;
  final String? providerId;
  final String? categoryId;
  final String? subscription;
  final String? packageType;
  final String? packageValue;
  final String? packageAmount;
  final int? used;
  final int? missed;
  final int? remaining;
  final String? subscribedon;
  final String? category;
  final String? statusText;
  final PackageDetails? packageDetails;
  final List<Services>? services;
  final List<dynamic>? addons;

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
    this.addons,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      subscriptionId: json['subscription_id'],
      providerId: json['provider_id'],
      categoryId: json['category_id'],
      subscription: json['subscription'],
      packageType: json['package_type'],
      packageValue: json['package_value'],
      packageAmount: json['package_amount'],
      used: json['used'],
      missed: json['missed'],
      remaining: json['remaining'],
      subscribedon: json['subscribedon'],
      category: json['category'],
      statusText: json['status_text'],
      packageDetails: json['package_details'] != null
          ? PackageDetails.fromJson(json['package_details'])
          : null,
      services: json['services'] != null
          ? (json['services'] as List)
              .map((e) => Services.fromJson(e))
              .toList()
          : [],
      addons: json['addons'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'subscription_id': subscriptionId,
        'provider_id': providerId,
        'category_id': categoryId,
        'subscription': subscription,
        'package_type': packageType,
        'package_value': packageValue,
        'package_amount': packageAmount,
        'used': used,
        'missed': missed,
        'remaining': remaining,
        'subscribedon': subscribedon,
        'category': category,
        'status_text': statusText,
        'package_details': packageDetails?.toJson(),
        'services': services?.map((e) => e.toJson()).toList(),
        'addons': addons,
      };
}

class PackageDetails {
  final String? type;
  final String? value;
  final String? amount;

  PackageDetails({
    this.type,
    this.value,
    this.amount,
  });

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    return PackageDetails(
      type: json['type'],
      value: json['value'],
      amount: json['amount'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'amount': amount,
      };
}

class Services {
  final String? subscriptionServiceId;
  final String? subCategoryId;
  final String? serviceId;
  final String? price;
  final String? discount;
  final String? type;
  final String? subscriptionId;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final String? providerId;
  final int? usedJobs;
  final int? missedJobs;

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
      usedJobs: json['used_jobs'],
      missedJobs: json['missed_jobs'],
    );
  }

  Map<String, dynamic> toJson() => {
        'subscription_service_id': subscriptionServiceId,
        'sub_category_id': subCategoryId,
        'service_id': serviceId,
        'price': price,
        'discount': discount,
        'type': type,
        'subscription_id': subscriptionId,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'provider_id': providerId,
        'used_jobs': usedJobs,
        'missed_jobs': missedJobs,
      };
}