import '../../domain/entities/image_input.dart';
import '../../domain/entities/denoise_result.dart';
import '../../domain/repositories/denoise_repository.dart';
import '../datasources/image_picker_datasource.dart';
import '../datasources/nafnet_model_datasource.dart';
import '../../../../services/storage_service.dart';
import '../models/image_input_model.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/app_exception.dart';

class DenoiseRepositoryImpl implements DenoiseRepository {
  final ImagePickerDatasource imagePickerDatasource;
  final NafnetModelDatasource nafnetModelDatasource;
  final StorageService storageService;

  DenoiseRepositoryImpl({
    required this.imagePickerDatasource,
    required this.nafnetModelDatasource,
    required this.storageService,
  });

  @override
  Future<ImageInput?> pickImageFromGallery() async {
    try {
      return await imagePickerDatasource.pickImageFromGallery();
    } on PermissionException catch (e) {
      throw PermissionFailure(e.message);
    } on ImagePickerException catch (e) {
      throw ImagePickerFailure(e.message);
    } catch (e) {
      throw ImagePickerFailure('Failed to pick image: $e');
    }
  }

  @override
  Future<ImageInput?> captureImageFromCamera() async {
    try {
      return await imagePickerDatasource.captureImageFromCamera();
    } on PermissionException catch (e) {
      throw PermissionFailure(e.message);
    } on ImagePickerException catch (e) {
      throw ImagePickerFailure(e.message);
    } catch (e) {
      throw ImagePickerFailure('Failed to capture image: $e');
    }
  }

  @override
  Future<DenoiseResult> runDenoise(ImageInput input, String task, String modelId) async {
    try {
      final inputModel = ImageInputModel(
        path: input.path,
        createdAt: input.createdAt,
      );
      return await nafnetModelDatasource.runDenoise(inputModel, task, modelId);
    } on ModelException catch (e) {
      throw ModelFailure(e.message);
    } catch (e) {
      throw UnknownFailure('Inference failed: $e');
    }
  }

  @override
  Future<String> saveDenoisedImage(String imagePath) async {
    try {
      return await storageService.saveImage(imagePath);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    } catch (e) {
      throw StorageFailure('Failed to save image: $e');
    }
  }

  @override
  Future<List<dynamic>> getAvailableModels() async {
    try {
      return await nafnetModelDatasource.getAvailableModels();
    } catch (e) {
      throw ModelFailure('Failed to fetch available models: $e');
    }
  }
}
