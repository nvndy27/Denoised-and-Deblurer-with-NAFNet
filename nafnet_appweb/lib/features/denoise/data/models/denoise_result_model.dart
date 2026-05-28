import '../../domain/entities/denoise_result.dart';

class DenoiseResultModel extends DenoiseResult {
  const DenoiseResultModel({
    required super.originalImagePath,
    required super.outputImagePath,
    required super.processedAt,
    required super.inferenceMode,
    super.inferenceTimeMs,
    super.processingDevice,
    super.qualityScore,
    super.inputSizeBytes,
    super.outputSizeBytes,
    super.brightnessIn,
    super.contrastIn,
    super.contrastOut,
    super.lapVarIn,
    super.lapVarOut,
    super.colorDistortion,
  });

  factory DenoiseResultModel.fromEntity(DenoiseResult entity) {
    return DenoiseResultModel(
      originalImagePath: entity.originalImagePath,
      outputImagePath: entity.outputImagePath,
      processedAt: entity.processedAt,
      inferenceMode: entity.inferenceMode,
      inferenceTimeMs: entity.inferenceTimeMs,
      processingDevice: entity.processingDevice,
      qualityScore: entity.qualityScore,
      inputSizeBytes: entity.inputSizeBytes,
      outputSizeBytes: entity.outputSizeBytes,
      brightnessIn: entity.brightnessIn,
      contrastIn: entity.contrastIn,
      contrastOut: entity.contrastOut,
      lapVarIn: entity.lapVarIn,
      lapVarOut: entity.lapVarOut,
      colorDistortion: entity.colorDistortion,
    );
  }

  factory DenoiseResultModel.fromJson(Map<String, dynamic> json) {
    return DenoiseResultModel(
      originalImagePath: json['originalImagePath'] as String,
      outputImagePath: json['outputImagePath'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String),
      inferenceMode: (json['inferenceMode'] as String?) ?? 'real',
      inferenceTimeMs: (json['inferenceTimeMs'] as num?)?.toDouble(),
      processingDevice: json['processingDevice'] as String?,
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      inputSizeBytes: json['inputSizeBytes'] as int?,
      outputSizeBytes: json['outputSizeBytes'] as int?,
      brightnessIn: (json['brightnessIn'] as num?)?.toDouble(),
      contrastIn: (json['contrastIn'] as num?)?.toDouble(),
      contrastOut: (json['contrastOut'] as num?)?.toDouble(),
      lapVarIn: (json['lapVarIn'] as num?)?.toDouble(),
      lapVarOut: (json['lapVarOut'] as num?)?.toDouble(),
      colorDistortion: json['colorDistortion'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalImagePath': originalImagePath,
      'outputImagePath': outputImagePath,
      'processedAt': processedAt.toIso8601String(),
      'inferenceMode': inferenceMode,
      'inferenceTimeMs': inferenceTimeMs,
      'processingDevice': processingDevice,
      'qualityScore': qualityScore,
      'inputSizeBytes': inputSizeBytes,
      'outputSizeBytes': outputSizeBytes,
      'brightnessIn': brightnessIn,
      'contrastIn': contrastIn,
      'contrastOut': contrastOut,
      'lapVarIn': lapVarIn,
      'lapVarOut': lapVarOut,
      'colorDistortion': colorDistortion,
    };
  }
}
