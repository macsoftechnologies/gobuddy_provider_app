class GetUpdateProfileModel {
  final String? status;
  final String? message;

  GetUpdateProfileModel({this.status, this.message});

  factory GetUpdateProfileModel.fromJson(Map<String, dynamic> json) {
    return GetUpdateProfileModel(
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