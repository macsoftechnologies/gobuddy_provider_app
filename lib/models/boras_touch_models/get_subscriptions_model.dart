class GetAllCategoriesModel {
  String? status;
  String? message;
  String? baseUrl;
  List<Category>? categories;

  GetAllCategoriesModel({
    this.status,
    this.message,
    this.baseUrl,
    this.categories,
  });

  factory GetAllCategoriesModel.fromJson(Map<String, dynamic> json) {
    return GetAllCategoriesModel(
      status: json['status'],
      message: json['message'],
      baseUrl: json['base_url'],
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((e) => Category.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'base_url': baseUrl,
      'categories': categories?.map((e) => e.toJson()).toList(),
    };
  }
}

class Category {
  String? category;
  String? id;
  String? image;
  String? displayOrder;
  String? count;
  String? location;
  List<SubCategory>? subCategories;

  Category({
    this.category,
    this.id,
    this.image,
    this.displayOrder,
    this.count,
    this.location,
    this.subCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      category: json['category'],
      id: json['id'],
      image: json['image'],
      displayOrder: json['display_order'],
      count: json['count'],
      location: json['location'],
      subCategories: json['sub_categories'] != null
          ? (json['sub_categories'] as List)
              .map((e) => SubCategory.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'id': id,
      'image': image,
      'display_order': displayOrder,
      'count': count,
      'location': location,
      'sub_categories': subCategories?.map((e) => e.toJson()).toList(),
    };
  }
}

class SubCategory {
  String? sid;
  String? subCategory;
  String? subImage;

  SubCategory({
    this.sid,
    this.subCategory,
    this.subImage,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      sid: json['sid'],
      subCategory: json['sub_category'],
      subImage: json['sub_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sid': sid,
      'sub_category': subCategory,
      'sub_image': subImage,
    };
  }
}