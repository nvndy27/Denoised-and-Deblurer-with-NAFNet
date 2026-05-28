import '../entities/image_input.dart';
import '../repositories/denoise_repository.dart';

class PickImageFromGallery {
  final DenoiseRepository repository;

  PickImageFromGallery(this.repository);

  Future<ImageInput?> call() {
    return repository.pickImageFromGallery();
  }
}
