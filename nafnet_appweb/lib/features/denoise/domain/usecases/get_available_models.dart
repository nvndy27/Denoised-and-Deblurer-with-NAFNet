import '../repositories/denoise_repository.dart';

class GetAvailableModels {
  final DenoiseRepository repository;

  GetAvailableModels(this.repository);

  Future<List<dynamic>> call() {
    return repository.getAvailableModels();
  }
}
