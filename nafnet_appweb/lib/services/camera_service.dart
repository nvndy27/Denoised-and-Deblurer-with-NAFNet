import 'package:camera/camera.dart';

class CameraService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _cameraController;

  /// Initializes the list of available cameras on the device.
  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      // Handle camera initialization error
      _cameras = [];
    }
  }

  /// Gets the available cameras.
  List<CameraDescription> get cameras => _cameras;

  /// Initializes a specific camera controller.
  Future<void> initializeController(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  /// Disposes of the camera controller.
  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }
}
