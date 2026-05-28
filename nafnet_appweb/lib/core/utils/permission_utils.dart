import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  PermissionUtils._();

  /// Requests camera permission and returns true if granted.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Requests storage permission and returns true if granted.
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (status.isGranted) return true;
    final result = await Permission.storage.request();
    return result.isGranted;
  }

  /// Requests photos permission and returns true if granted.
  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;
    final result = await Permission.photos.request();
    return result.isGranted;
  }
}
