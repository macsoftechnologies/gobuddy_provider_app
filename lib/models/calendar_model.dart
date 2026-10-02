class GetCalendarModel {
  String? status;
  String? month;
  Jobs? jobs;

  GetCalendarModel({this.status, this.month, this.jobs});

  factory GetCalendarModel.fromJson(Map<String, dynamic> json) {
    return GetCalendarModel(
      status: json['status'] as String?,
      month: json['month'] as String?,
      jobs: json['jobs'] != null ? Jobs.fromJson(json['jobs']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'month': month,
      if (jobs != null) 'jobs': jobs!.toJson(),
    };
  }
}

class Jobs {
  List<Calendar>? calendar;
  List<Orders>? orders;
  List<Vacations>? vacations;

  Jobs({this.calendar, this.orders, this.vacations});

  factory Jobs.fromJson(Map<String, dynamic> json) {
    return Jobs(
      calendar: json['calendar'] != null
          ? List<Calendar>.from(json['calendar'].map((x) => Calendar.fromJson(x)))
          : null,
      orders: json['orders'] != null
          ? List<Orders>.from(json['orders'].map((x) => Orders.fromJson(x)))
          : null,
      vacations: json['vacations'] != null
          ? List<Vacations>.from(json['vacations'].map((x) => Vacations.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (calendar != null) 'calendar': calendar!.map((x) => x.toJson()).toList(),
      if (orders != null) 'orders': orders!.map((x) => x.toJson()).toList(),
      if (vacations != null) 'vacations': vacations!.map((x) => x.toJson()).toList(),
    };
  }
}

class Calendar {
  String? date;
  String? status;
  String? startTime;
  String? endTime;
  List<String>? scheduleTimes;

  Calendar({this.date, this.status, this.startTime, this.endTime, this.scheduleTimes});

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      date: json['date'] as String?,
      status: json['status'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      scheduleTimes: json['schedule_times'] != null
          ? List<String>.from(json['schedule_times'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'status': status,
      'start_time': startTime,
      'end_time': endTime,
      'schedule_times': scheduleTimes,
    };
  }
}

class Orders {
  String? id;
  String? userId;
  String? jobCalenderId;
  String? providerId;
  String? serviceId;
  String? scheduleDate;
  String? scheduleTime;
  String? price;
  String? quantity;
  String? status;
  String? createdAt;
  String? userName;
  String? serviceName;
  String? location;
  String? latitude;
  String? longitude;
  String? landmark;

  Orders({
    this.id,
    this.userId,
    this.jobCalenderId,
    this.providerId,
    this.serviceId,
    this.scheduleDate,
    this.scheduleTime,
    this.price,
    this.quantity,
    this.status,
    this.createdAt,
    this.userName,
    this.serviceName,
    this.location,
    this.latitude,
    this.longitude,
    this.landmark,
  });

  factory Orders.fromJson(Map<String, dynamic> json) {
    return Orders(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      jobCalenderId: json['job_calender_id'] as String?,
      providerId: json['provider_id'] as String?,
      serviceId: json['service_id'] as String?,
      scheduleDate: json['schedule_date'] as String?,
      scheduleTime: json['schedule_time'] as String?,
      price: json['price'] as String?,
      quantity: json['quantity'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] as String?,
      userName: json['user_name'] as String?,
      serviceName: json['service_name'] as String?,
      location: json['location'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      landmark: json['landmark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'job_calender_id': jobCalenderId,
      'provider_id': providerId,
      'service_id': serviceId,
      'schedule_date': scheduleDate,
      'schedule_time': scheduleTime,
      'price': price,
      'quantity': quantity,
      'status': status,
      'created_at': createdAt,
      'user_name': userName,
      'service_name': serviceName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
    };
  }
}

class Vacations {
  String? date;
  String? startTime;
  String? endTime;

  Vacations({this.date, this.startTime, this.endTime});

  factory Vacations.fromJson(Map<String, dynamic> json) {
    return Vacations(
      date: json['date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}
