class GetServicesModel {
  final String? status;
  final String? message;
  final String? baseUrl;
  final List<Services>? services;

  GetServicesModel({
    this.status,
    this.message,
    this.baseUrl,
    this.services,
  });

  factory GetServicesModel.fromJson(Map<String, dynamic> json) {
    return GetServicesModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      baseUrl: json['base_url']?.toString(),
      services: json['services'] != null
          ? (json['services'] as List)
              .map((e) => Services.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'base_url': baseUrl,
      'services': services?.map((e) => e.toJson()).toList(),
    };
  }
}

class Services {
  final String? id;
  final String? title;
  final String? price;
  final String? presponsibility;
  final String? cresponsibility;
  final String? note;
  final String? serviceImage;
  final String? time;
  final int? averageRating;
  final String? totalReviews;
  final List<dynamic>? gallery;
  final int? bookings;

  Services({
    this.id,
    this.title,
    this.price,
    this.presponsibility,
    this.cresponsibility,
    this.note,
    this.serviceImage,
    this.time,
    this.averageRating,
    this.totalReviews,
    this.gallery,
    this.bookings,
  });

  factory Services.fromJson(Map<String, dynamic> json) {
    return Services(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      price: json['price']?.toString(),
      presponsibility: json['presponsibility']?.toString(),
      cresponsibility: json['cresponsibility']?.toString(),
      note: json['note']?.toString(),
      serviceImage: json['service_image']?.toString(),
      time: json['time']?.toString(),
      averageRating: json['average_rating'] is int
          ? json['average_rating']
          : int.tryParse(json['average_rating']?.toString() ?? ''),
      totalReviews: json['total_reviews']?.toString(),
      gallery: json['gallery'] != null
          ? List<dynamic>.from(json['gallery'])
          : [],
      bookings: json['bookings'] is int
          ? json['bookings']
          : int.tryParse(json['bookings']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'presponsibility': presponsibility,
      'cresponsibility': cresponsibility,
      'note': note,
      'service_image': serviceImage,
      'time': time,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'gallery': gallery,
      'bookings': bookings,
    };
  }
}