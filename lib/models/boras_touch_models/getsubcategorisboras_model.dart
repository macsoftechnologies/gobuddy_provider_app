class GetSubCategoriesModel {
  final String? status;
  final String? message;
  final String? baseUrl;
  final String? categoryName;
  final List<SubCategory>? subCategory;

  GetSubCategoriesModel({
    this.status,
    this.message,
    this.baseUrl,
    this.categoryName,
    this.subCategory,
  });

  factory GetSubCategoriesModel.fromJson(Map<String, dynamic> json) {
    return GetSubCategoriesModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      baseUrl: json['base_url']?.toString(),
      categoryName: json['category_name']?.toString(),
      subCategory: json['sub_category'] != null
          ? (json['sub_category'] as List)
              .map((e) => SubCategory.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'base_url': baseUrl,
      'category_name': categoryName,
      'sub_category': subCategory?.map((e) => e.toJson()).toList(),
    };
  }
}

class SubCategory {
  final String? id;
  final String? categoryId;
  final String? subCategory;
  final String? status;
  final String? createdDate;
  final String? updatedDate;
  final String? displayOrder;
  final String? subImage;
  final String? locationId;
  final String? locationName;

  SubCategory({
    this.id,
    this.categoryId,
    this.subCategory,
    this.status,
    this.createdDate,
    this.updatedDate,
    this.displayOrder,
    this.subImage,
    this.locationId,
    this.locationName,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id']?.toString(),
      categoryId: json['category_id']?.toString(),
      subCategory: json['sub_category']?.toString(),
      status: json['status']?.toString(),
      createdDate: json['created_date']?.toString(),
      updatedDate: json['updated_date']?.toString(),
      displayOrder: json['display_order']?.toString(),
      subImage: json['sub_image']?.toString(),
      locationId: json['location_id']?.toString(),
      locationName: json['location_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'sub_category': subCategory,
      'status': status,
      'created_date': createdDate,
      'updated_date': updatedDate,
      'display_order': displayOrder,
      'sub_image': subImage,
      'location_id': locationId,
      'location_name': locationName,
    };
  }
}