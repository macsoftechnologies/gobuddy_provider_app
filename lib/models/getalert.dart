class GetMyLiveAlert {
  final String? status;
  final String? message;
  final int? count;
  final List<Orders> orders;

  GetMyLiveAlert({
    this.status,
    this.message,
    this.count,
    this.orders = const [],
  });

  factory GetMyLiveAlert.fromJson(Map<String, dynamic> json) {
    return GetMyLiveAlert(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count']?.toString() ?? ''),
      orders: (json['orders'] as List?)
              ?.map((e) => Orders.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'count': count,
      'orders': orders.map((e) => e.toJson()).toList(),
    };
  }
}


class Orders {
  final String? orderId;
  final String? jobCalendarId;
  final String? orderTxn;
  final String? createdAt;
  final String? status;
  final String? orderStatus;
  final String? serviceId;
  final String? serviceName;
  final String? serviceImage;
  final String? scheduleDate;
  final String? scheduleTime;
  final String? quantity;
  final String? price;
  final String? notification;
  final String? note;

  Orders({
    this.orderId,
    this.jobCalendarId,
    this.orderTxn,
    this.createdAt,
    this.status,
    this.orderStatus,
    this.serviceId,
    this.serviceName,
    this.serviceImage,
    this.scheduleDate,
    this.scheduleTime,
    this.quantity,
    this.price,
    this.notification,
    this.note,
  });

  factory Orders.fromJson(Map<String, dynamic> json) {
    return Orders(
      orderId: json['order_id']?.toString(),
      jobCalendarId: json['job_calender_id']?.toString(),
      orderTxn: json['order_txn']?.toString(),
      createdAt: json['created_at']?.toString(),
      status: json['status']?.toString(),
      orderStatus: json['order_status']?.toString(),
      serviceId: json['service_id']?.toString(),
      serviceName: json['service_name']?.toString(),
      serviceImage: json['service_image']?.toString(),
      scheduleDate: json['schedule_date']?.toString(),
      scheduleTime: json['schedule_time']?.toString(),
      quantity: json['quantity']?.toString(),
      price: json['price']?.toString(),
      notification: json['notification']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'job_calender_id': jobCalendarId,
      'order_txn': orderTxn,
      'created_at': createdAt,
      'status': status,
      'order_status': orderStatus,
      'service_id': serviceId,
      'service_name': serviceName,
      'service_image': serviceImage,
      'schedule_date': scheduleDate,
      'schedule_time': scheduleTime,
      'quantity': quantity,
      'price': price,
      'notification': notification,
      'note': note,
    };
  }
}
