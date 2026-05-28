import '../../../../services/nafnet_api_service.dart';
import '../models/image_input_model.dart';
import '../models/denoise_result_model.dart';

abstract class NafnetModelDatasource {
  Future<DenoiseResultModel> runDenoise(ImageInputModel input, String task, String modelId);
  Future<List<dynamic>> getAvailableModels();
}

class NafnetModelDatasourceImpl implements NafnetModelDatasource {
  final NafnetApiService apiService;

  NafnetModelDatasourceImpl(this.apiService);

  @override
  Future<DenoiseResultModel> runDenoise(ImageInputModel input, String task, String modelId) async {
    final response = await apiService.denoiseImage(input.path, task, modelId);
    return DenoiseResultModel(
      originalImagePath: input.path,
      outputImagePath: response.outputPath,
      processedAt: DateTime.now(),
      inferenceMode: response.inferenceMode,
      inferenceTimeMs: response.inferenceTimeMs,
      processingDevice: response.processingDevice,
      qualityScore: response.qualityScore,
      inputSizeBytes: response.inputSizeBytes,
      outputSizeBytes: response.outputSizeBytes,
      brightnessIn: response.brightnessIn,
      contrastIn: response.contrastIn,
      contrastOut: response.contrastOut,
      lapVarIn: response.lapVarIn,
      lapVarOut: response.lapVarOut,
      colorDistortion: response.colorDistortion,
    );
  }

  @override
  Future<List<dynamic>> getAvailableModels() async {
    return apiService.getAvailableModels();
  }
}

