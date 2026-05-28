import '../entities/image_input.dart';
import '../entities/denoise_result.dart';

abstract class DenoiseRepository {
  /// Picks an image from the device gallery.
  Future<ImageInput?> pickImageFromGallery();

  /// Captures an image using the device camera.
  Future<ImageInput?> captureImageFromCamera();

  /// Runs the NAFNet restoration model on the [input] image with specified [task] and [modelId].
  Future<DenoiseResult> runDenoise(ImageInput input, String task, String modelId);

  /// Saves the enhanced image to public storage.
  /// Returns the saved file path.
  Future<String> saveDenoisedImage(String imagePath);

  /// Gets the list of available models from the backend.
  Future<List<dynamic>> getAvailableModels();
}
