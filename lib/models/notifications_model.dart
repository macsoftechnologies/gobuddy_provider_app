class GetNotificationsModel {
  final String? status;
  final String? message;
  final List<Data> data;
  final int? count;

  GetNotificationsModel({
    this.status,
    this.message,
    this.data = const [],
    this.count,
  });

  factory GetNotificationsModel.fromJson(Map<String, dynamic> json) {
    return GetNotificationsModel(
      status: json['status'] as String?, // "success"
      message: json['message'] as String?, // "Notifications fetched successfully"
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Data.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      count: json['count'] as int?, // may be null if API does not provide
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((v) => v.toJson()).toList(),
      'count': count,
    };
  }
}

class Data {
  final String? id;
  final String? userId;
  final String? userType;
  final String? title;
  final String? subtitle;
  final String? serviceName;
  final String? location;
  final String? personName;
  final String? dateTime;
  final String? amount;
  final String? status;
  final String? isRead;
  final String? createdAt;

  Data({
    this.id,
    this.userId,
    this.userType,
    this.title,
    this.subtitle,
    this.serviceName,
    this.location,
    this.personName,
    this.dateTime,
    this.amount,
    this.status,
    this.isRead,
    this.createdAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      userType: json['user_type'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      serviceName: json['service_name'] as String?,
      location: json['location'] as String?,
      personName: json['person_name'] as String?,
      dateTime: json['date_time'] as String?,
      amount: json['amount'] as String?,
      status: json['status'] as String?, // "new"
      isRead: json['is_read'] as String?, // "0" or "1"
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_type': userType,
      'title': title,
      'subtitle': subtitle,
      'service_name': serviceName,
      'location': location,
      'person_name': personName,
      'date_time': dateTime,
      'amount': amount,
      'status': status,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }
}