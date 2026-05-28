# NAFNet Image Denoiser Flutter App

A clean-architecture Flutter application that demonstrates image denoising and quality restoration using the **NAFNet** deep learning model.

## Features

- **Pick Images**: Load images from the local photo gallery or capture photos using the camera.
- **AI-powered Enhancement**: Simulated/real edge inference with the NAFNet model to denoise and restore photos.
- **Interactive Before-After Comparison**: A premium sliding split-view to compare the original image side-by-side with the denoised version.
- **Save Result**: Copy the enhanced image to the application's document folder.

---

## Project Structure

This application is built using a simplified **Clean Architecture** style (`presentation` → `domain` → `data` → `services`):

```text
nafnet_flutter_app/
├── assets/
│   ├── models/            # TFLite model files (nafnet.tflite)
│   └── images/            # Asset images (placeholder.png, app_logo.png)
│
├── lib/
│   ├── main.dart          # App startup and dependency injection invocation
│   ├── app/               # App configuration (routes, theme, app wrapper)
│   ├── core/              # Constants, custom widgets, utilities, and errors
│   ├── features/
│   │   └── denoise/       # Image Denoising feature (Clean Architecture layer)
│   │       ├── data/      # Datasources, models, and repo implementations
│   │       ├── domain/    # Entities, usecases, and repo interfaces
│   │       └── presentation/ # View pages, controllers, and custom widgets
│   │
│   ├── services/          # Low-level integrations (Camera, Picker, Model inference, Storage)
│   └── injection_container.dart # Manual dependency injection setup
```

---

## Technical Specifications

- **Flutter version**: Stable (Null Safety)
- **State Management**: `ChangeNotifier` + `Provider`
- **Main packages**:
  - `image_picker` (image acquisition)
  - `camera` (device camera control)
  - `path_provider` (local file systems)
  - `permission_handler` (system permission checks)
  - `image` (advanced image decoding, resizing, pixel manipulation in Dart)
  - `tflite_flutter` (TensorFlow Lite edge execution)
  - `provider` (dependency injection and reactive state)

---

## Setup & Running Guide

### 1. Restore Platform Folders (Android/iOS)
Since this project code was written manually, you may need to recreate platform files (Gradle build systems, iOS runner configuration files, etc.) before compiling.

Open your terminal, navigate to the `nafnet_flutter_app` folder, and execute:
```bash
flutter create .
```
This command automatically generates the missing platform directories (`android`, `ios`, `windows`, etc.) based on the configurations listed in `pubspec.yaml`.

### 2. Download Dependencies
Fetch the Flutter packages declared in the configuration:
```bash
flutter pub get
```

### 3. Run the Application
Launch the app on a connected emulator or physical device:
```bash
flutter run
```

---

## Integrating a Real NAFNet Model

The file `assets/models/nafnet.tflite` is currently a placeholder file. In the mock stage, the app will run inference by delaying for 2 seconds and returning the original image. 

To use real inference:
1. Obtain or export a NAFNet model to TensorFlow Lite format (e.g. `nafnet_rgb_small.tflite`).
2. Replace `assets/models/nafnet.tflite` with your model file.
3. Uncomment the image preprocessing, inference, and postprocessing pipeline in `lib/services/nafnet_inference_service.dart`.
4. Run `flutter run`.
