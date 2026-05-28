abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class ImagePickerFailure extends Failure {
  const ImagePickerFailure(super.message);
}

class ModelFailure extends Failure {
  const ModelFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
