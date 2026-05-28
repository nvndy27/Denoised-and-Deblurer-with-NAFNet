import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nafnet_flutter_app/app/app.dart';
import 'package:nafnet_flutter_app/features/denoise/presentation/controllers/denoise_controller.dart';
import 'package:nafnet_flutter_app/injection_container.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize dependencies
    await initDependencies();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider<DenoiseController>(
        create: (_) => InjectionContainer.denoiseController,
        child: const NafnetApp(),
      ),
    );

    // Verify that our app name is displayed on the Home Page
    expect(find.text('NAFNet Image Denoiser'), findsOneWidget);
  });
}
