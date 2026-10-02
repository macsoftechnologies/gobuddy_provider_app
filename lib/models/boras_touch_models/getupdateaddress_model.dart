class GetUpdateAddressModel {
  final String? status;
  final String? message;

  GetUpdateAddressModel({
    this.status,
    this.message,
  });

  factory GetUpdateAddressModel.fromJson(Map<String, dynamic> json) {
    return GetUpdateAddressModel(
      status: json['status'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }
}