import 'package:flutter/material.dart';
import '../features/denoise/presentation/pages/task_selection_page.dart';
import '../features/denoise/presentation/pages/denoise_home_page.dart';
import '../features/denoise/presentation/pages/image_preview_page.dart';
import '../features/denoise/presentation/pages/result_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String denoiseHome = '/home';
  static const String preview = '/preview';
  static const String result = '/result';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const TaskSelectionPage(),
        denoiseHome: (context) => const DenoiseHomePage(),
        preview: (context) => const ImagePreviewPage(),
        result: (context) => const ResultPage(),
      };
}
