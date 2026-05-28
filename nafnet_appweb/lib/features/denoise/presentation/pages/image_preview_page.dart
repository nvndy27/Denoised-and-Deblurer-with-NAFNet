import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/image_preview_card.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../controllers/denoise_controller.dart';
import '../states/denoise_state.dart';

class ImagePreviewPage extends StatelessWidget {
  const ImagePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DenoiseController>(
      builder: (context, controller, child) {
        final state = controller.state;
        final isProcessing = state.status == DenoiseStatus.processing;
        final selectedImagePath = state.selectedImage?.path ?? '';
        final File? imageFile = selectedImagePath.isNotEmpty ? File(selectedImagePath) : null;

        // Check if the selected model has weight file on backend
        final models = state.availableModels;
        bool isAvailable = true; // Default to true if not loaded yet
        if (models.isNotEmpty) {
          final modelInfo = models.firstWhere(
            (m) => m['model_id'] == state.modelId,
            orElse: () => null,
          );
          if (modelInfo != null) {
            isAvailable = modelInfo['available'] ?? false;
          }
        }

        Future<void> enhanceImage() async {
          await controller.runDenoise();

          if (!context.mounted) return;

          if (controller.state.status == DenoiseStatus.success) {
            // Go to result page and replace current page
            Navigator.pushReplacementNamed(context, '/result');
          } else if (controller.state.status == DenoiseStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(controller.state.errorMessage ?? 'Restoration failed.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Preview Image'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: isProcessing ? null : () => Navigator.pop(context),
            ),
          ),
          body: LoadingOverlay(
            isLoading: isProcessing,
            message: 'Phục hồi chất lượng ảnh...',
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        
                        // Missing Checkpoint Warning Banner
                        if (!isAvailable)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade300, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: Colors.red.shade800),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Chưa tìm thấy checkpoint cho model này.',
                                      style: TextStyle(
                                        color: Colors.red.shade900, 
                                        fontSize: 13, 
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        Expanded(
                          child: Center(
                            child: ImagePreviewCard(
                              imageFile: imageFile,
                              label: state.task == 'deblur' ? 'Ảnh bị mờ nhòe (Input)' : 'Ảnh bị nhiễu hạt (Input)',
                              aspectRatioStr: 'Original',
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        CustomButton(
                          text: isAvailable ? 'Bắt đầu phục hồi' : 'Chưa tìm thấy checkpoint cho model này.',
                          icon: Icons.auto_awesome,
                          onPressed: (imageFile == null || isProcessing || !isAvailable) ? null : enhanceImage,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: isProcessing
                              ? null
                              : () {
                                  controller.reset();
                                  Navigator.pop(context);
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel & Choose Another'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
