import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/denoise_controller.dart';
import '../../../../core/constants/app_constants.dart';

class TaskSelectionPage extends StatefulWidget {
  const TaskSelectionPage({super.key});

  @override
  State<TaskSelectionPage> createState() => _TaskSelectionPageState();
}

class _TaskSelectionPageState extends State<TaskSelectionPage> {
  @override
  void initState() {
    super.initState();
    // Query backend models capabilities right at startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DenoiseController>(context, listen: false).loadAvailableModels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.2),
              theme.colorScheme.surface,
              theme.colorScheme.secondaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 52,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn một chức năng để bắt đầu phục hồi hình ảnh',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    
                    // Functional tasks list
                    Consumer<DenoiseController>(
                      builder: (context, controller, child) {
                        final models = controller.state.availableModels;
                        
                        Map<String, dynamic>? getModelInfo(String modelId) {
                          try {
                            return models.firstWhere((m) => m['model_id'] == modelId);
                          } catch (_) {
                            return null;
                          }
                        }

                        return Column(
                          children: [
                            _buildTaskCard(
                              context: context,
                              title: 'Khử Nhiễu Ảnh',
                              subtitle: 'Loại bỏ nhiễu hạt (noise) chụp trong điều kiện thiếu sáng hoặc cảm biến nhỏ (NAFNet-SIDD).',
                              icon: Icons.photo_filter_rounded,
                              color: Colors.indigo,
                              modelInfo: getModelInfo('nafnet_sidd_width32'),
                              onTap: () {
                                controller.setTaskAndModel('denoise', 'nafnet_sidd_width32');
                                Navigator.pushNamed(context, '/home');
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTaskCard(
                              context: context,
                              title: 'Làm Nét Ảnh Mờ',
                              subtitle: 'Khắc phục hiện tượng ảnh chụp bị rung tay, nhòe mờ chuyển động hoặc mất nét (NAFNet-GoPro).',
                              icon: Icons.lens_blur_rounded,
                              color: Colors.teal,
                              modelInfo: getModelInfo('nafnet_gopro_width64'),
                              onTap: () {
                                controller.setTaskAndModel('deblur', 'nafnet_gopro_width64');
                                Navigator.pushNamed(context, '/home');
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const Spacer(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Map<String, dynamic>? modelInfo,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surface.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.18),
                        color.withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
