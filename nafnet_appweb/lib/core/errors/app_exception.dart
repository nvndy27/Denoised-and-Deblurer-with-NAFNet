class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class PermissionException extends AppException {
  PermissionException(super.message, [super.code]);
}

class ImagePickerException extends AppException {
  ImagePickerException(super.message, [super.code]);
}

class ModelException extends AppException {
  ModelException(super.message, [super.code]);
}

class StorageException extends AppException {
  StorageException(super.message, [super.code]);
}
