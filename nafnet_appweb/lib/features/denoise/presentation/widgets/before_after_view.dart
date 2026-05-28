import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/image_utils.dart';

class BeforeAfterView extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;
  final double height;
  final String afterLabel;
  final String selectedAspectRatio;

  const BeforeAfterView({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
    this.height = 380.0,
    this.afterLabel = 'Enhanced',
    this.selectedAspectRatio = 'Original',
  });

  @override
  State<BeforeAfterView> createState() => _BeforeAfterViewState();
}

class _BeforeAfterViewState extends State<BeforeAfterView> {
  double _sliderPosition = 0.5; // Center position (0.0 to 1.0)
  double _aspectRatio = 16 / 9; // Default fallback aspect ratio
  late ImageProvider _beforeImageProvider;
  late ImageProvider _afterImageProvider;

  @override
  void initState() {
    super.initState();
    _initImageProviders();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(BeforeAfterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.beforeImagePath != widget.beforeImagePath ||
        oldWidget.afterImagePath != widget.afterImagePath) {
      _initImageProviders();
      _resolveImageAspectRatio();
    }
  }

  void _initImageProviders() {
    _beforeImageProvider = getImageProvider(widget.beforeImagePath);
    _afterImageProvider = getImageProvider(widget.afterImagePath);
  }

  void _resolveImageAspectRatio() {
    try {
      _beforeImageProvider.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener(
          (ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _aspectRatio = info.image.width / info.image.height;
              });
            }
          },
          onError: (dynamic exception, StackTrace? stackTrace) {
            debugPrint('Failed to resolve image aspect ratio: $exception');
          },
        ),
      );
    } catch (e) {
      debugPrint('Error initiating image aspect ratio resolution: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double activeRatio = _aspectRatio;
    switch (widget.selectedAspectRatio) {
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
        activeRatio = _aspectRatio;
        break;
    }

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: widget.height,
            ),
            child: AspectRatio(
              aspectRatio: activeRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _sliderPosition = (details.localPosition.dx / width).clamp(0.0, 1.0);
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Bottom Layer: Original Image
                        Image(
                          image: _beforeImageProvider,
                          fit: BoxFit.cover,
                          width: width,
                          height: height,
                          errorBuilder: (context, error, stackTrace) => _buildErrorState(theme, 'Original'),
                        ),
                        
                        // Label "Original"
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(165),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Original',
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        // 2. Top Layer: Denoised Image (Clipped dynamically based on slider)
                        ClipRect(
                          clipper: _BeforeAfterClipper(_sliderPosition),
                          child: Image(
                            image: _afterImageProvider,
                            fit: BoxFit.cover,
                            width: width,
                            height: height,
                            errorBuilder: (context, error, stackTrace) => _buildErrorState(theme, 'Denoised'),
                          ),
                        ),

                        // Label dynamically passed from parent
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(216),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.afterLabel,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                  // 3. Vertical Divider Line
                  Positioned(
                    left: width * _sliderPosition - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: Colors.white,
                    ),
                  ),

                  // 4. Sliding Handle Knob
                  Positioned(
                    left: width * _sliderPosition - 20,
                    top: height / 2 - 20,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(76),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chevron_left, color: Colors.white, size: 14),
                            Icon(Icons.chevron_right, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  ),
),
);
}

  Widget _buildErrorState(ThemeData theme, String label) {
    return Container(
      color: theme.colorScheme.secondaryContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 48, color: theme.colorScheme.error.withAlpha(153)),
            const SizedBox(height: 8),
            Text('Failed to load $label image', style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }

}

class _BeforeAfterClipper extends CustomClipper<Rect> {
  final double clipFactor;

  _BeforeAfterClipper(this.clipFactor);

  @override
  Rect getClip(Size size) {
    // Show the Denoised image from the slider position to the right edge.
    return Rect.fromLTRB(size.width * clipFactor, 0.0, size.width, size.height);
  }

  @override
  bool shouldReclip(_BeforeAfterClipper oldClipper) => oldClipper.clipFactor != clipFactor;
}
