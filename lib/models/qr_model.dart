class GetMyQrModel {
  final String? status;
  final String? message;
  final QrData? data;

  GetMyQrModel({
    this.status,
    this.message,
    this.data,
  });

  /// Factory constructor
  factory GetMyQrModel.fromJson(Map<String, dynamic> json) {
    return GetMyQrModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? QrData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class QrData {
  final String? providerId;
  final String? providerName;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? qrcodeImage;
  final String? qrcodeUploadedAt;

  QrData({
    this.providerId,
    this.providerName,
    this.email,
    this.phone,
    this.profileImage,
    this.qrcodeImage,
    this.qrcodeUploadedAt,
  });

  /// Factory constructor
  factory QrData.fromJson(Map<String, dynamic> json) {
    return QrData(
      providerId: json['provider_id'],
      providerName: json['provider_name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      qrcodeImage: json['qrcode_image'],
      qrcodeUploadedAt: json['qrcode_uploaded_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'provider_name': providerName,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'qrcode_image': qrcodeImage,
      'qrcode_uploaded_at': qrcodeUploadedAt,
    };
  }
}
