import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/image_input.dart';
import '../../../../services/web_camera_helper.dart';
import '../controllers/denoise_controller.dart';
import '../states/denoise_state.dart';

class DenoiseHomePage extends StatelessWidget {
  const DenoiseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Provider.of<DenoiseController>(context);
    final state = controller.state;
    final isDeblur = state.task == 'deblur';
    
    final pageTitle = isDeblur ? 'NAFNet Image Deblurer' : 'NAFNet Image Denoiser';
    final pageSubtitle = isDeblur 
        ? 'Làm nét hình ảnh bằng trí tuệ nhân tạo NAFNet' 
        : 'Khử nhiễu hình ảnh bằng trí tuệ nhân tạo NAFNet';
    final guideText = isDeblur 
        ? 'Chọn một bức ảnh bị mờ hoặc nhòe. Model NAFNet-GoPro sẽ khôi phục chi tiết và làm nét ảnh.' 
        : 'Chọn một bức ảnh bị nhiễu hạt. Model NAFNet-SIDD sẽ khôi phục độ mịn và làm sạch nhiễu.';

    Future<void> pickImage({required bool isGallery}) async {
      if (isGallery) {
        await controller.pickFromGallery();
        if (!context.mounted) return;
        if (controller.state.status == DenoiseStatus.preview) {
          Navigator.pushNamed(context, '/preview');
        } else if (controller.state.status == DenoiseStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.state.errorMessage ?? 'Failed to select image.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        if (kIsWeb) {
          try {
            final dataUrl = await WebCameraHelper.captureImage(context);
            if (dataUrl != null) {
              controller.setSelectedImage(ImageInput(path: dataUrl, createdAt: DateTime.now()));
              if (!context.mounted) return;
              Navigator.pushNamed(context, '/preview');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        } else {
          await controller.captureFromCamera();
          if (!context.mounted) return;
          if (controller.state.status == DenoiseStatus.preview) {
            Navigator.pushNamed(context, '/preview');
          } else if (controller.state.status == DenoiseStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(controller.state.errorMessage ?? 'Failed to capture image.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.15),
                            theme.colorScheme.secondary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome_motion_rounded,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Header Text
                  Text(
                    pageTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pageSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(204),
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  // Guide Card
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.secondaryContainer.withAlpha(76),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              guideText,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Primary Action Buttons
                  CustomButton(
                    text: 'Chọn từ thư viện',
                    icon: Icons.photo_library_rounded,
                    onPressed: () => pickImage(isGallery: true),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => pickImage(isGallery: false),
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: const Text(
                      'Chụp từ camera',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
