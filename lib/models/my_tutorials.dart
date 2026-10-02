class GetTutorialsModel {
  final String status;
  final String message;
  final List<Tutorials> tutorials;

  GetTutorialsModel({
    required this.status,
    required this.message,
    required this.tutorials,
  });

  // Factory constructor for JSON deserialization
  factory GetTutorialsModel.fromJson(Map<String, dynamic> json) {
    return GetTutorialsModel(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      tutorials: (json['tutorials'] as List<dynamic>?)
              ?.map((item) => Tutorials.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'tutorials': tutorials.map((v) => v.toJson()).toList(),
    };
  }
}

class Tutorials {
  final String videoLink;
  final String title;
  final String description;

  Tutorials({
    required this.videoLink,
    required this.title,
    required this.description,
  });

  // Factory constructor for JSON deserialization
  factory Tutorials.fromJson(Map<String, dynamic> json) {
    return Tutorials(
      videoLink: json['video_link'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'video_link': videoLink,
      'title': title,
      'description': description,
    };
  }
}
