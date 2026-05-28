import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/image_utils.dart';

class ImagePreviewCard extends StatelessWidget {
  final File? imageFile;
  final double? width;
  final double? height;
  final String label;
  final String aspectRatioStr;

  const ImagePreviewCard({
    super.key,
    required this.imageFile,
    this.width,
    this.height,
    this.label = 'Image Preview',
    this.aspectRatioStr = 'Original',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasImage = imageFile != null && imageFile!.path.isNotEmpty;

    double? activeRatio;
    switch (aspectRatioStr) {
      case '1:1':
        activeRatio = 1.0;
        break;
      case '16:9':
        activeRatio = 16.0 / 9.0;
        break;
      case '9:16':
        activeRatio = 9.0 / 16.0;
        break;
      case '4:3':
        activeRatio = 4.0 / 3.0;
        break;
      case '3:4':
        activeRatio = 3.0 / 4.0;
        break;
      case 'Original':
      default:
        activeRatio = null;
        break;
    }

    final Widget imageWidget = hasImage
        ? Image(
            image: getImageProvider(imageFile!.path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPlaceholder(theme);
            },
          )
        : _buildPlaceholder(theme);

    final Widget cardContent = Stack(
      fit: StackFit.expand,
      children: [
        Center(child: imageWidget),
        
        // Label banner
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black54,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );

    final Widget cardWidget = Container(
      width: width ?? double.infinity,
      height: activeRatio != null ? null : (height ?? 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(76),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(76),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );

    if (activeRatio != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: activeRatio,
          child: cardWidget,
        ),
      );
    } else {
      return cardWidget;
    }
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 64,
          color: theme.colorScheme.primary.withAlpha(127),
        ),
        const SizedBox(height: 12),
        Text(
          'No image selected',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(178),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: theme.colorScheme.error.withAlpha(127),
        ),
        const SizedBox(height: 12),
        Text(
          'Failed to load image',
          style: TextStyle(
            color: theme.colorScheme.error.withAlpha(178),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}
