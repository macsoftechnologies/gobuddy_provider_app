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
      status: json['status'] as String?,
      message: json['message'] as String?,
      userId: json['user_id'] as int?,
      phoneNumber: json['phone_number'] as String?,
      viewAs: json['view_as'] as String?,
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