import 'package:flutter/foundation.dart';
import 'services/image_picker_service.dart';
import 'services/camera_service.dart';
import 'services/image_preprocessing_service.dart';
import 'services/image_postprocessing_service.dart';
import 'services/nafnet_api_service.dart';
import 'services/storage_service.dart';
import 'features/denoise/data/datasources/image_picker_datasource.dart';
import 'features/denoise/data/datasources/nafnet_model_datasource.dart';
import 'features/denoise/data/repositories/denoise_repository_impl.dart';
import 'features/denoise/domain/repositories/denoise_repository.dart';
import 'features/denoise/domain/usecases/pick_image_from_gallery.dart';
import 'features/denoise/domain/usecases/capture_image_from_camera.dart';
import 'features/denoise/domain/usecases/run_nafnet_denoise.dart';
import 'features/denoise/domain/usecases/save_denoised_image.dart';
import 'features/denoise/domain/usecases/get_available_models.dart';
import 'features/denoise/presentation/controllers/denoise_controller.dart';

class InjectionContainer {
  InjectionContainer._();

  // Services
  static final ImagePickerService imagePickerService = ImagePickerService();
  static final CameraService cameraService = CameraService();
  static final ImagePreprocessingService imagePreprocessingService = ImagePreprocessingService();
  static final ImagePostprocessingService imagePostprocessingService = ImagePostprocessingService();
  
  static final NafnetApiService nafnetApiService = NafnetApiService();
  static final StorageService storageService = StorageService();

  // Datasources
  static final ImagePickerDatasource imagePickerDatasource = ImagePickerDatasourceImpl(
    imagePickerService,
  );
  static final NafnetModelDatasource nafnetModelDatasource = NafnetModelDatasourceImpl(
    nafnetApiService,
  );

  // Repository
  static final DenoiseRepository denoiseRepository = DenoiseRepositoryImpl(
    imagePickerDatasource: imagePickerDatasource,
    nafnetModelDatasource: nafnetModelDatasource,
    storageService: storageService,
  );

  // Usecases
  static final PickImageFromGallery pickImageFromGallery = PickImageFromGallery(denoiseRepository);
  static final CaptureImageFromCamera captureImageFromCamera = CaptureImageFromCamera(denoiseRepository);
  static final RunNafnetDenoise runNafnetDenoise = RunNafnetDenoise(denoiseRepository);
  static final SaveDenoisedImage saveDenoisedImage = SaveDenoisedImage(denoiseRepository);
  static final GetAvailableModels getAvailableModels = GetAvailableModels(denoiseRepository);

  // Controller factory (returns a new instance or can be mapped as a singleton depending on provider setup)
  static DenoiseController get denoiseController => DenoiseController(
        pickImageFromGalleryUseCase: pickImageFromGallery,
        captureImageFromCameraUseCase: captureImageFromCamera,
        runNafnetDenoiseUseCase: runNafnetDenoise,
        saveDenoisedImageUseCase: saveDenoisedImage,
        getAvailableModelsUseCase: getAvailableModels,
      );

  /// Initializes dependencies synchronously or asynchronously.
  /// Pre-loads the NAFNet model so that it is warm and ready for inference.
  static Future<void> init() async {
    // Perform a non-blocking server health check for debugging purposes
    nafnetApiService.checkServerHealth().then((isHealthy) {
      debugPrint('NafnetApp: Backend server is ${isHealthy ? "ONLINE" : "OFFLINE or UNREACHABLE"}');
    });
  }
}

/// Global dependency initialization function.
Future<void> initDependencies() async {
  await InjectionContainer.init();
}

