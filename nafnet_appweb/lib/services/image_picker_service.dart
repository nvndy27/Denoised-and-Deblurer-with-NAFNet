import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/errors/app_exception.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery. Returns the path or null if cancelled.
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      throw ImagePickerException('Failed to pick image from gallery: $e');
    }
  }

  /// Captures an image from the camera. Returns the path or null if cancelled.
  Future<String?> captureFromCamera() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          throw ImagePickerException('Quyền truy cập Camera bị từ chối.');
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      throw ImagePickerException('Không thể mở camera: $e');
    }
  }
}
