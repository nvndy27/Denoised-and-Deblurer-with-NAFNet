import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Returns an [ImageProvider] for a given path string.
/// Correctly handles base64 Data URLs on web/mobile, local file paths on native mobile,
/// and standard network URLs/Blob URLs.
ImageProvider getImageProvider(String path) {
  if (path.isEmpty) {
    return const AssetImage('assets/images/placeholder.png'); // fallback placeholder
  }
  
  if (path.startsWith('data:image/')) {
    try {
      final String base64Data = path.substring(path.indexOf(',') + 1);
      return MemoryImage(base64Decode(base64Data));
    } catch (e) {
      debugPrint('Error decoding base64 image provider: $e');
    }
  }
  
  if (kIsWeb) {
    return NetworkImage(path);
  } else {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}

class ImageUtils {
  /// Normalizes the pixel values of the image from [0, 255] to [0.0, 1.0].
  /// Returns a flat list of normalized floats in RGB order.
  static List<double> normalizeImageBytes(img.Image image) {
    final List<double> normalized = [];
    for (final pixel in image) {
      normalized.add(pixel.r.toDouble() / 255.0);
      normalized.add(pixel.g.toDouble() / 255.0);
      normalized.add(pixel.b.toDouble() / 255.0);
    }
    return normalized;
  }
}
