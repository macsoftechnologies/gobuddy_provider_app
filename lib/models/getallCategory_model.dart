class GetAllCategoriesModel {
  String? status;
  String? message;
  String? baseUrl;
  List<Categories>? categories;

  GetAllCategoriesModel({
    this.status,
    this.message,
    this.baseUrl,
    this.categories,
  });

factory GetAllCategoriesModel.fromJson(Map<String, dynamic> json) {
  return GetAllCategoriesModel(
    status: json['status']?.toString(),
    message: json['message']?.toString(),
    baseUrl: json['base_url']?.toString(),
    categories: json['categories'] != null
        ? List<Categories>.from(
            json['categories'].map((v) => Categories.fromJson(v)))
        : [],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'base_url': baseUrl,
      'categories': categories?.map((v) => v.toJson()).toList(),
    };
  }
}

class Categories {
  String? category;
  String? id;
  String? image;
  String? displayOrder;
  String? count;
  List<SubCategories>? subCategories;

  Categories({
    this.category,
    this.id,
    this.image,
    this.displayOrder,
    this.count,
    this.subCategories,
  });

factory Categories.fromJson(Map<String, dynamic> json) {
  return Categories(
    category: json['category']?.toString(),
    id: json['id']?.toString(),
    image: json['image']?.toString(),
    displayOrder: json['display_order']?.toString(),

    // ✅ FIXED (IMPORTANT)
    count: json['count']?.toString(),

    subCategories: json['sub_categories'] != null
        ? List<SubCategories>.from(
            json['sub_categories'].map((v) => SubCategories.fromJson(v)))
        : null,
  );
}
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'id': id,
      'image': image,
      'display_order': displayOrder,
      'count': count,
      'sub_categories': subCategories?.map((v) => v.toJson()).toList(),
    };
  }
}

class SubCategories {
  String? sid;
  String? subCategory;
  String? subImage;

  SubCategories({this.sid, this.subCategory, this.subImage});
factory SubCategories.fromJson(Map<String, dynamic> json) {
  return SubCategories(
    sid: json['sid']?.toString(),
    subCategory: json['sub_category']?.toString(),
    subImage: json['sub_image']?.toString(),
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