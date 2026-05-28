import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';

class ResultActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onProcessAnother;
  final VoidCallback onGoHome;
  final bool isSaving;
  final String task;

  const ResultActionButtons({
    super.key,
    required this.onSave,
    required this.onProcessAnother,
    required this.onGoHome,
    this.isSaving = false,
    this.task = 'denoise',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Save Image',
                icon: Icons.save_alt_rounded,
                isLoading: isSaving,
                onPressed: onSave,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: task == 'deblur' ? 'Deblur Another' : 'Denoise Another',
                icon: Icons.photo_library_outlined,
                backgroundColor: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
                onPressed: onProcessAnother,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onGoHome,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
