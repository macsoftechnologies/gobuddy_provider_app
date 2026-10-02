class GetAddonsModel {
  final String? status;
  final String? message;
  final String? categoryName;
  final List<Addon>? addons;

  GetAddonsModel({
    this.status,
    this.message,
    this.categoryName,
    this.addons,
  });

  factory GetAddonsModel.fromJson(Map<String, dynamic> json) {
    return GetAddonsModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      categoryName: json['category_name']?.toString(),
      addons: json['addons'] != null
          ? (json['addons'] as List)
              .map((e) => Addon.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'category_name': categoryName,
      'addons': addons?.map((e) => e.toJson()).toList(),
    };
  }
}

class Addon {
  final String? id;
  final String? categoryId;
  final String? addonService;
  final String? status;
  final String? createdDate;
  final String? updatedDate;

  Addon({
    this.id,
    this.categoryId,
    this.addonService,
    this.status,
    this.createdDate,
    this.updatedDate,
  });

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: json['id']?.toString(),
      categoryId: json['category_id']?.toString(),
      addonService: json['addon_service']?.toString(),
      status: json['status']?.toString(),
      createdDate: json['created_date']?.toString(),
      updatedDate: json['updated_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'addon_service': addonService,
      'status': status,
      'created_date': createdDate,
      'updated_date': updatedDate,
    };
  }
}