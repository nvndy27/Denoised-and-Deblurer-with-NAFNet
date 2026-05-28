import 'dart:async';
import 'dart:html' as html;
import '../core/errors/app_exception.dart';

class StorageService {
  /// Triggers a browser download of the image.
  /// imagePath on Web is a base64 data URL.
  Future<String> saveImage(String imagePath) async {
    try {
      if (!imagePath.startsWith('data:image/')) {
        throw StorageException('Định dạng dữ liệu ảnh trên Web không hợp lệ.');
      }
      
      // Extract file extension from data URL header, default to png
      String extension = 'png';
      final mimeMatch = RegExp(r'^data:image/(\w+);base64,').firstMatch(imagePath);
      if (mimeMatch != null && mimeMatch.groupCount >= 1) {
        extension = mimeMatch.group(1)!;
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'enhanced_$timestamp.$extension';
      
      // Create anchor element and trigger download programmatically
      final anchor = html.AnchorElement(href: imagePath)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
        
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      
      return fileName;
    } catch (e) {
      throw StorageException('Lỗi tải ảnh về trình duyệt: $e');
    }
  }
}
