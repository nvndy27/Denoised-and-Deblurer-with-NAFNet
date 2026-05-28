import '../entities/image_input.dart';
import '../entities/denoise_result.dart';
import '../repositories/denoise_repository.dart';

class RunNafnetDenoise {
  final DenoiseRepository repository;

  RunNafnetDenoise(this.repository);

  Future<DenoiseResult> call(ImageInput input, String task, String modelId) {
    return repository.runDenoise(input, task, modelId);
  }
}
