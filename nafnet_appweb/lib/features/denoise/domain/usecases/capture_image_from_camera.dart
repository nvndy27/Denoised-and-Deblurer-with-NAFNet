import '../entities/image_input.dart';
import '../repositories/denoise_repository.dart';

class CaptureImageFromCamera {
  final DenoiseRepository repository;

  CaptureImageFromCamera(this.repository);

  Future<ImageInput?> call() {
    return repository.captureImageFromCamera();
  }
}
