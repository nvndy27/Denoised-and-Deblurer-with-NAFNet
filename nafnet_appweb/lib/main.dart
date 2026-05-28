import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'injection_container.dart';

void main() async {
  // Ensure the widget framework is initialized before loading async resources
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize service dependencies and load the model
  await initDependencies();

  runApp(
    ChangeNotifierProvider(
      create: (_) => InjectionContainer.denoiseController,
      child: const NafnetApp(),
    ),
  );
}
