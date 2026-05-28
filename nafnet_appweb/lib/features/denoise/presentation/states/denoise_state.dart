import '../../domain/entities/image_input.dart';
import '../../domain/entities/denoise_result.dart';

enum DenoiseStatus {
  initial,
  picking,
  preview,
  processing,
  success,
  failure,
}

class DenoiseState {
  final DenoiseStatus status;
  final ImageInput? selectedImage;
  final DenoiseResult? result;
  final String? errorMessage;
  final String task;
  final String modelId;
  final List<dynamic> availableModels;
  final String selectedAspectRatio;

  const DenoiseState({
    required this.status,
    this.selectedImage,
    this.result,
    this.errorMessage,
    required this.task,
    required this.modelId,
    required this.availableModels,
    this.selectedAspectRatio = 'Original',
  });

  factory DenoiseState.initial() {
    return const DenoiseState(
      status: DenoiseStatus.initial,
      task: 'denoise',
      modelId: 'nafnet_sidd_width32',
      availableModels: [],
      selectedAspectRatio: 'Original',
    );
  }

  DenoiseState copyWith({
    DenoiseStatus? status,
    ImageInput? selectedImage,
    DenoiseResult? result,
    String? errorMessage,
    String? task,
    String? modelId,
    List<dynamic>? availableModels,
    String? selectedAspectRatio,
  }) {
    return DenoiseState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      task: task ?? this.task,
      modelId: modelId ?? this.modelId,
      availableModels: availableModels ?? this.availableModels,
      selectedAspectRatio: selectedAspectRatio ?? this.selectedAspectRatio,
    );
  }

  @override
  String toString() {
    return 'DenoiseState(status: $status, selectedImage: $selectedImage, result: $result, error: $errorMessage, task: $task, modelId: $modelId, selectedAspectRatio: $selectedAspectRatio)';
  }
}
