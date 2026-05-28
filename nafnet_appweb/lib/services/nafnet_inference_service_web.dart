import 'package:flutter/foundation.dart';
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

  /// Loads the TFLite model safely. (Always mock loaded on web)
  Future<void> loadModel() async {
    debugPrint('NafnetInferenceService (Web): Running in mock mode (tflite not supported on web).');
  }

  /// Runs image enhancement. Always performs a mock inference (delay 2s).
  Future<String> runInference(String imagePath) async {
    // Simulate model inference time (delay 2s)
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('NafnetInferenceService (Web): Finished mock inference.');
    return imagePath;
  }
}
