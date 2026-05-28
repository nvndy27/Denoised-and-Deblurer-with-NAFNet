import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImagePostprocessingService {
  /// Converts the model output tensor back into a saved JPEG image file.
  /// 
  /// Workflow:
  /// 1. Takes the raw float output tensor from model inference.
  /// 2. Scales the values from [0.0, 1.0] back to [0, 255] RGB.
  /// 3. Reconstructs an image and encodes it to JPEG/PNG format.
  /// 4. Saves the denoised image to a temporary or persistent file path.
  Future<String> postprocessImage(List<dynamic> outputTensor, String originalPath) async {
    // The expected outputTensor shape is [1, height, width, 3]
    final batch = outputTensor[0] as List<dynamic>;
    final height = batch.length;
    final width = batch[0].length;

    // Create a new empty image
    final image = img.Image(width: width, height: height);

    // Populate pixels by de-normalizing values [0.0, 1.0] -> [0, 255]
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final rgb = batch[y][x] as List<dynamic>;
        
        // Clamp and scale
        final r = ((rgb[0] as num) * 255.0).clamp(0.0, 255.0).toInt();
        final g = ((rgb[1] as num) * 255.0).clamp(0.0, 255.0).toInt();
        final b = ((rgb[2] as num) * 255.0).clamp(0.0, 255.0).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    // Encode the image back to JPEG bytes
    final jpegBytes = img.encodeJpg(image);

    // Save to a temporary file
    final tempDir = await getTemporaryDirectory();
    final denoisedFile = File('${tempDir.path}/denoised_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await denoisedFile.writeAsBytes(jpegBytes);

    return denoisedFile.path;
  }
}
