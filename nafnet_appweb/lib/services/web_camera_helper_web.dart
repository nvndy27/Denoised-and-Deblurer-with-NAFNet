import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebCameraHelper {
  static Future<String?> captureImage(BuildContext context) async {
    final completer = Completer<String?>();
    
    // Create unique ID for view factory registration
    final viewId = 'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';
    
    // Create HTML elements
    final videoElement = html.VideoElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..autoplay = true;
      
    // Register the video element as a platform view using dart:ui_web
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) => videoElement);
    
    html.MediaStream? stream;
    
    try {
      // Request camera access with null check
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('Trình duyệt hoặc thiết bị của bạn không hỗ trợ MediaDevices (Camera API).');
      }
      stream = await mediaDevices.getUserMedia({'video': true});
      videoElement.srcObject = stream;
    } catch (e) {
      debugPrint('WebCameraHelper: Camera permission or access error: $e');
      completer.completeError('Không thể truy cập Camera. Vui lòng cấp quyền camera trong trình duyệt.');
      return completer.future;
    }
    
    // Show Flutter Dialog containing the camera preview and capture button
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBar(
                    title: const Text('Chụp ảnh từ Webcam', style: TextStyle(fontWeight: FontWeight.bold)),
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          // Stop streams and close
                          stream?.getTracks().forEach((track) => track.stop());
                          Navigator.pop(dialogContext);
                          completer.complete(null);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      height: 360,
                      child: HtmlElementView(viewType: viewId),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        try {
                          // Create canvas to capture the current frame
                          final canvas = html.CanvasElement(
                            width: videoElement.videoWidth > 0 ? videoElement.videoWidth : 640,
                            height: videoElement.videoHeight > 0 ? videoElement.videoHeight : 480,
                          );
                          final ctx = canvas.context2D;
                          ctx.drawImage(videoElement, 0, 0);
                          
                          // Convert canvas to Data URL (base64 PNG)
                          final dataUrl = canvas.toDataUrl('image/png');
                          
                          // Stop camera stream
                          stream?.getTracks().forEach((track) => track.stop());
                          
                          Navigator.pop(dialogContext);
                          completer.complete(dataUrl);
                        } catch (e) {
                          debugPrint('WebCameraHelper capture error: $e');
                          completer.completeError('Lỗi khi chụp ảnh từ video: $e');
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    return completer.future;
  }
}
