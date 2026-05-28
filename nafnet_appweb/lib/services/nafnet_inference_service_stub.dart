import 'image_preprocessing_service.dart';
import 'image_postprocessing_service.dart';

class NafnetInferenceService {
  final ImagePreprocessingService preprocessingService;
  final ImagePostprocessingService postprocessingService;

  NafnetInferenceService({
    required this.preprocessingService,
    required this.postprocessingService,
  });

  bool get isModelLoaded => false;

  Future<void> loadModel() async {
    // Stub implementation
  }

  Future<String> runInference(String imagePath) async {
    // Stub implementation: fallback mock delay
    await Future.delayed(const Duration(seconds: 2));
    return imagePath;
  }
}
