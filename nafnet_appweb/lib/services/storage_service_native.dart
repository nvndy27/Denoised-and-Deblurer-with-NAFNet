import 'dart:io';
import 'package:gal/gal.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/file_utils.dart';

class StorageService {
  /// Saves the enhanced image from its current temporary path to the device's public photo gallery.
  /// Returns a success status path / filename description.
  Future<String> saveImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw StorageException('Tập tin ảnh gốc không tồn tại tại: $imagePath');
      }

      // Check and request gallery permission using Gal API
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
        final nowHasAccess = await Gal.hasAccess();
        if (!nowHasAccess) {
          throw StorageException('Quyền truy cập thư viện ảnh bị từ chối.');
        }
      }

      // Save the image to the public device gallery
      await Gal.putImage(imagePath);
      
      final fileName = FileUtils.getFileName(imagePath);
      return 'Thư viện ảnh ($fileName)';
    } catch (e) {
      throw StorageException('Không thể lưu ảnh vào thư viện thiết bị: $e');
    }
  }
}
