class GetDropdownModel {
  final bool? status;
  final List<PlanData>? data;

  GetDropdownModel({
    this.status,
    this.data,
  });

  factory GetDropdownModel.fromJson(Map<String, dynamic> json) {
    return GetDropdownModel(
      status: json['status'] as bool?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => PlanData.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.map((e) => e.toJson()).toList(),
    };
  }
}

class PlanData {
  final String? planId;
  final String? plan;
  final List<Package>? packages;

  PlanData({
    this.planId,
    this.plan,
    this.packages,
  });

  factory PlanData.fromJson(Map<String, dynamic> json) {
    return PlanData(
      planId: json['plan_id']?.toString(),
      plan: json['plan']?.toString(),
      packages: json['packages'] != null
          ? (json['packages'] as List)
              .map((e) => Package.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'plan': plan,
      'packages': packages?.map((e) => e.toJson()).toList(),
    };
  }
}

class Package {
  final String? id;
  final String? packageType;
  final String? packageValue;
  final String? package;
  final int? amount;
  final String? status;

  Package({
    this.id,
    this.packageType,
    this.packageValue,
    this.package,
    this.amount,
    this.status,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id']?.toString(),
      packageType: json['package_type']?.toString(),
      packageValue: json['package_value']?.toString(),
      package: json['package']?.toString(),
      amount: json['amount'] is int
          ? json['amount']
          : int.tryParse(json['amount']?.toString() ?? ''),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_type': packageType,
      'package_value': packageValue,
      'package': package,
      'amount': amount,
      'status': status,
    };
  }
}