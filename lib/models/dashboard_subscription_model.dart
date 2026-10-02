class GetMySubscriptionModel {
  final String? status;
  final String? message;
  final List<Data>? data;

  GetMySubscriptionModel({
    this.status,
    this.message,
    this.data,
  });

  factory GetMySubscriptionModel.fromJson(Map<String, dynamic> json) {
    return GetMySubscriptionModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? List<Data>.from(json['data'].map((x) => Data.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data?.map((x) => x.toJson()).toList(),
      };
}

class Data {
  final String? subscriptionId;
  final String? providerId;
  final String? categoryId;
  final String? subscription;
  final String? jobs;
  final String? package;
  final int? used;
  final int? missed;
  final int? remaining;
  final String? paymentId;
  final String? subscribedon;
  final String? amount;
  final String? savingAmount;
  final String? coupon;
  final String? category;
  final String? statusText;
  final List<Services>? services;
  final List<dynamic>? addons; // fixed

  Data({
    this.subscriptionId,
    this.providerId,
    this.categoryId,
    this.subscription,
    this.jobs,
    this.package,
    this.used,
    this.missed,
    this.remaining,
    this.paymentId,
    this.subscribedon,
    this.amount,
    this.savingAmount,
    this.coupon,
    this.category,
    this.statusText,
    this.services,
    this.addons,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      subscriptionId: json['subscription_id'],
      providerId: json['provider_id'],
      categoryId: json['category_id'],
      subscription: json['subscription'],
      jobs: json['jobs'],
      package: json['package'],
      used: json['used'],
      missed: json['missed'],
      remaining: json['remaining'],
      paymentId: json['payment_id'],
      subscribedon: json['subscribedon'],
      amount: json['amount'],
      savingAmount: json['saving_amount'],
      coupon: json['coupon'],
      category: json['category'],
      statusText: json['status_text'],
      services: json['services'] != null
          ? List<Services>.from(
              json['services'].map((x) => Services.fromJson(x)))
          : [],
      addons: json['addons'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'subscription_id': subscriptionId,
        'provider_id': providerId,
        'category_id': categoryId,
        'subscription': subscription,
        'jobs': jobs,
        'package': package,
        'used': used,
        'missed': missed,
        'remaining': remaining,
        'payment_id': paymentId,
        'subscribedon': subscribedon,
        'amount': amount,
        'saving_amount': savingAmount,
        'coupon': coupon,
        'category': category,
        'status_text': statusText,
        'services': services?.map((x) => x.toJson()).toList(),
        'addons': addons,
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
  final dynamic subCategory; // fixed
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
    this.subCategory,
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
      subCategory: json['sub_category'],
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
        'sub_category': subCategory,
        'used_jobs': usedJobs,
        'missed_jobs': missedJobs,
      };
}