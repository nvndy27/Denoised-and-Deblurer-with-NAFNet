import '../repositories/denoise_repository.dart';

class SaveDenoisedImage {
  final DenoiseRepository repository;

  SaveDenoisedImage(this.repository);

  Future<String> call(String imagePath) {
    return repository.saveDenoisedImage(imagePath);
  }
}
