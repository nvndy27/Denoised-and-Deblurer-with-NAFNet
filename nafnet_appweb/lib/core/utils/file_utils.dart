import 'dart:io';

class FileUtils {
  FileUtils._();

  /// Gets the file name from a path.
  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Checks if a file exists at the given path.
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Gets file size in bytes.
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }
}
