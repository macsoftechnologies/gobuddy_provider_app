class GetPlansModel {
  bool? status;
  List<PlanDataOne>? data;

  GetPlansModel({
    this.status,
    this.data,
  });

  factory GetPlansModel.fromJson(Map<String, dynamic> json) {
    return GetPlansModel(
      status: json['status'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => PlanDataOne.fromJson(e))
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

class PlanDataOne {
  String? id;
  String? planId;
  String? plan;
  String? packageType;
  String? packageValue;
  String? package;
  String? amount;
  String? extraCharges;
  String? status;

  PlanDataOne({
    this.id,
    this.planId,
    this.plan,
    this.packageType,
    this.packageValue,
    this.package,
    this.amount,
    this.extraCharges,
    this.status,
  });

  factory PlanDataOne.fromJson(Map<String, dynamic> json) {
    return PlanDataOne(
      id: json['id'],
      planId: json['plan_id'],
      plan: json['plan'],
      packageType: json['package_type'],
      packageValue: json['package_value'],
      package: json['package'],
      amount: json['amount'],
      extraCharges: json['extra_charges'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'plan': plan,
      'package_type': packageType,
      'package_value': packageValue,
      'package': package,
      'amount': amount,
      'extra_charges': extraCharges,
      'status': status,
    };
  }
}