import '../../../../services/image_picker_service.dart';
import '../models/image_input_model.dart';

abstract class ImagePickerDatasource {
  Future<ImageInputModel?> pickImageFromGallery();
  Future<ImageInputModel?> captureImageFromCamera();
}

class ImagePickerDatasourceImpl implements ImagePickerDatasource {
  final ImagePickerService imagePickerService;

  ImagePickerDatasourceImpl(this.imagePickerService);

  @override
  Future<ImageInputModel?> pickImageFromGallery() async {
    final path = await imagePickerService.pickFromGallery();
    if (path == null) return null;
    return ImageInputModel(path: path, createdAt: DateTime.now());
  }

  @override
  Future<ImageInputModel?> captureImageFromCamera() async {
    final path = await imagePickerService.captureFromCamera();
    if (path == null) return null;
    return ImageInputModel(path: path, createdAt: DateTime.now());
  }
}
