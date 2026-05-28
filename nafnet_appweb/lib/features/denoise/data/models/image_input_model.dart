import '../../domain/entities/image_input.dart';

class ImageInputModel extends ImageInput {
  const ImageInputModel({
    required super.path,
    required super.createdAt,
  });

  factory ImageInputModel.fromEntity(ImageInput entity) {
    return ImageInputModel(
      path: entity.path,
      createdAt: entity.createdAt,
    );
  }

  factory ImageInputModel.fromJson(Map<String, dynamic> json) {
    return ImageInputModel(
      path: json['path'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
