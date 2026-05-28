class DenoiseResult {
  final String originalImagePath;
  final String outputImagePath;
  final DateTime processedAt;
  final String inferenceMode; // 'real' or 'mock'
  final double? inferenceTimeMs;
  final String? processingDevice;
  final double? qualityScore;
  final int? inputSizeBytes;
  final int? outputSizeBytes;
  final double? brightnessIn;
  final double? contrastIn;
  final double? contrastOut;
  final double? lapVarIn;
  final double? lapVarOut;
  final bool? colorDistortion;

  const DenoiseResult({
    required this.originalImagePath,
    required this.outputImagePath,
    required this.processedAt,
    required this.inferenceMode,
    this.inferenceTimeMs,
    this.processingDevice,
    this.qualityScore,
    this.inputSizeBytes,
    this.outputSizeBytes,
    this.brightnessIn,
    this.contrastIn,
    this.contrastOut,
    this.lapVarIn,
    this.lapVarOut,
    this.colorDistortion,
  });

  @override
  String toString() {
    return 'DenoiseResult(original: $originalImagePath, output: $outputImagePath, processedAt: $processedAt, inferenceMode: $inferenceMode, inferenceTimeMs: $inferenceTimeMs, device: $processingDevice, score: $qualityScore, inputSize: $inputSizeBytes, outputSize: $outputSizeBytes, brightnessIn: $brightnessIn, contrastIn: $contrastIn, contrastOut: $contrastOut, lapVarIn: $lapVarIn, lapVarOut: $lapVarOut, colorDistortion: $colorDistortion)';
  }
}
