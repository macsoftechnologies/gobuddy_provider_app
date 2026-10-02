class GetSubscriptionSuccessModel {
  final bool? status;
  final String? message;
  final int? subscriptionId;

  GetSubscriptionSuccessModel({
    this.status,
    this.message,
    this.subscriptionId,
  });

  factory GetSubscriptionSuccessModel.fromJson(Map<String, dynamic> json) {
    return GetSubscriptionSuccessModel(
      status: json['status'] as bool?,
      message: json['message']?.toString(),
      subscriptionId: json['subscription_id'] is int
          ? json['subscription_id']
          : int.tryParse(json['subscription_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'subscription_id': subscriptionId,
    };
  }
}