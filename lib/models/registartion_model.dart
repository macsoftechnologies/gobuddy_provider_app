class GetRegistrationModel {
  final String? status;
  final String? message;
  final int? userId;
  final String? phoneNumber;
  final String? viewAs;

  GetRegistrationModel({
    this.status,
    this.message,
    this.userId,
    this.phoneNumber,
    this.viewAs,
  });

  factory GetRegistrationModel.fromJson(Map<String, dynamic> json) {
    return GetRegistrationModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      phoneNumber: json['phone_number']?.toString(),
      viewAs: json['view_as']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'user_id': userId,
      'phone_number': phoneNumber,
      'view_as': viewAs,
    };
  }
}