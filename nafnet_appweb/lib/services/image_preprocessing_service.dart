import 'dart:io';
import 'package:image/image.dart' as img;
import '../core/utils/image_utils.dart';

class ImagePreprocessingService {
  /// Preprocesses the input image file for the NAFNet model.
  /// 
  /// Workflow:
  /// 1. Reads the image from [imagePath].
  /// 2. Resizes it to [width] x [height] (usually 256x256).
  /// 3. Converts pixels into a normalized float array of shape [1, width, height, 3] with values in the range [0.0, 1.0].
  Future<List<dynamic>> preprocessImage(String imagePath, int width, int height) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception("Input image file does not exist: $imagePath");
    }

    // Load the image bytes
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception("Unable to decode input image.");
    }

    // Resize image using the image utility
    final resized = img.copyResize(image, width: width, height: height);

    // Normalize image pixel values from [0, 255] to [0.0, 1.0]
    final normalizedData = ImageUtils.normalizeImageBytes(resized);

    // Reshape to match the input tensor shape: [1, height, width, channels]
    // Here we wrap the normalized data in a list to represent batch size of 1
    final inputTensor = [
      List.generate(
        height,
        (y) => List.generate(
          width,
          (x) {
            final offset = (y * width + x) * 3;
            return [
              normalizedData[offset],     // Red
              normalizedData[offset + 1], // Green
              normalizedData[offset + 2], // Blue
            ];
          },
        ),
      )
    ];

    return inputTensor;
  }
}
