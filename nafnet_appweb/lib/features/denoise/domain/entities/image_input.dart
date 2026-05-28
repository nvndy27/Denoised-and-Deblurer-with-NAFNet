class ImageInput {
  final String path;
  final DateTime createdAt;

  const ImageInput({
    required this.path,
    required this.createdAt,
  });

  @override
  String toString() => 'ImageInput(path: $path, createdAt: $createdAt)';
}
