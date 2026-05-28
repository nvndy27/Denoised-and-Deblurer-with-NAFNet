import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'routes.dart';
import 'theme.dart';

class NafnetApp extends StatelessWidget {
  const NafnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
