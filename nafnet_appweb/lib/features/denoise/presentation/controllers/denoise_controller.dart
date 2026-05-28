import 'package:flutter/foundation.dart';
import '../../domain/entities/image_input.dart';
import '../../domain/usecases/pick_image_from_gallery.dart';
import '../../domain/usecases/capture_image_from_camera.dart';
import '../../domain/usecases/run_nafnet_denoise.dart';
import '../../domain/usecases/save_denoised_image.dart';
import '../../domain/usecases/get_available_models.dart';
import '../states/denoise_state.dart';

class DenoiseController extends ChangeNotifier {
  final PickImageFromGallery pickImageFromGalleryUseCase;
  final CaptureImageFromCamera captureImageFromCameraUseCase;
  final RunNafnetDenoise runNafnetDenoiseUseCase;
  final SaveDenoisedImage saveDenoisedImageUseCase;
  final GetAvailableModels getAvailableModelsUseCase;

  DenoiseState _state = DenoiseState.initial();

  DenoiseController({
    required this.pickImageFromGalleryUseCase,
    required this.captureImageFromCameraUseCase,
    required this.runNafnetDenoiseUseCase,
    required this.saveDenoisedImageUseCase,
    required this.getAvailableModelsUseCase,
  });

  DenoiseState get state => _state;

  void _updateState(DenoiseState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Sets the selected task and updates the default model.
  void setTaskAndModel(String task, String modelId) {
    _updateState(_state.copyWith(
      task: task,
      modelId: modelId,
      status: DenoiseStatus.initial, // Reset status when switching tasks
      selectedImage: null,
      result: null,
    ));
  }

  /// Sets the selected image manually.
  void setSelectedImage(ImageInput image) {
    _updateState(_state.copyWith(
      status: DenoiseStatus.preview,
      selectedImage: image,
    ));
  }

  /// Loads the list of available models from backend on startup.
  Future<void> loadAvailableModels() async {
    try {
      final models = await getAvailableModelsUseCase();
      _updateState(_state.copyWith(availableModels: models));
      
      // Auto-configure default model based on the fetched list if needed
      if (models.isNotEmpty) {
        final taskModels = models.where((m) => m['task'] == _state.task).toList();
        if (taskModels.isNotEmpty) {
          // If current modelId is not in the list, set to the first valid model of this task
          final containsCurrent = taskModels.any((m) => m['model_id'] == _state.modelId);
          if (!containsCurrent) {
            _updateState(_state.copyWith(modelId: taskModels.first['model_id'] as String));
          }
        }
      }
    } catch (e) {
      debugPrint('DenoiseController: Failed to load models: $e');
    }
  }

  /// Triggers image selection from the gallery.
  Future<void> pickFromGallery() async {
    _updateState(_state.copyWith(status: DenoiseStatus.picking));
    try {
      final image = await pickImageFromGalleryUseCase();
      if (image != null) {
        _updateState(_state.copyWith(
          status: DenoiseStatus.preview,
          selectedImage: image,
        ));
      } else {
        _updateState(_state.copyWith(status: DenoiseStatus.initial));
      }
    } catch (e) {
      _updateState(_state.copyWith(
        status: DenoiseStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Triggers camera image capture.
  Future<void> captureFromCamera() async {
    _updateState(_state.copyWith(status: DenoiseStatus.picking));
    try {
      final image = await captureImageFromCameraUseCase();
      if (image != null) {
        _updateState(_state.copyWith(
          status: DenoiseStatus.preview,
          selectedImage: image,
        ));
      } else {
        _updateState(_state.copyWith(status: DenoiseStatus.initial));
      }
    } catch (e) {
      _updateState(_state.copyWith(
        status: DenoiseStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Performs the NAFNet model denoising/deblurring on the selected image.
  Future<void> runDenoise() async {
    if (_state.selectedImage == null) return;
    
    _updateState(_state.copyWith(status: DenoiseStatus.processing));
    try {
      final result = await runNafnetDenoiseUseCase(
        _state.selectedImage!, 
        _state.task, 
        _state.modelId
      );
      _updateState(_state.copyWith(
        status: DenoiseStatus.success,
        result: result,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: DenoiseStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Saves the enhanced image to the device files.
  Future<String?> saveResult() async {
    if (_state.result == null) return null;
    
    try {
      final savedPath = await saveDenoisedImageUseCase(_state.result!.outputImagePath);
      return savedPath;
    } catch (e) {
      _updateState(_state.copyWith(
        status: DenoiseStatus.failure,
        errorMessage: 'Failed to save image: $e',
      ));
      return null;
    }
  }

  /// Sets the selected aspect ratio.
  void setAspectRatio(String ratio) {
    _updateState(_state.copyWith(
      selectedAspectRatio: ratio,
    ));
  }

  /// Resets the application state back to default.
  void reset() {
    _updateState(DenoiseState.initial().copyWith(
      availableModels: _state.availableModels, // preserve loaded models
      task: _state.task,
      modelId: _state.modelId,
    ));
  }
}
