import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../core/errors/app_exception.dart';

class DenoiseApiResponse {
  final String outputPath;
  final String inferenceMode;
  final double? inferenceTimeMs;
  final String? processingDevice;
  final double? qualityScore;
  final int? inputSizeBytes;
  final int? outputSizeBytes;
  final double? brightnessIn;
  final double? contrastIn;
  final double? contrastOut;
  final double? lapVarIn;
  final double? lapVarOut;
  final bool? colorDistortion;

  DenoiseApiResponse({
    required this.outputPath,
    required this.inferenceMode,
    this.inferenceTimeMs,
    this.processingDevice,
    this.qualityScore,
    this.inputSizeBytes,
    this.outputSizeBytes,
    this.brightnessIn,
    this.contrastIn,
    this.contrastOut,
    this.lapVarIn,
    this.lapVarOut,
    this.colorDistortion,
  });
}

class NafnetApiService {
  final http.Client _client;

  NafnetApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Check server connectivity and returns true if server status is 'ok'
  Future<bool> checkServerHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.healthUrl))
          .timeout(const Duration(seconds: 3));
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('NafnetApiService: Server health check failed: $e');
      return false;
    }
  }

  /// Fetch list of available models from backend.
  Future<List<dynamic>> getAvailableModels() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/models'))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['models'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      debugPrint('NafnetApiService: Failed to fetch models: $e');
      return [];
    }
  }

  /// Sends a local image file to the Python backend to be processed via NAFNet.
  /// Returns a DenoiseApiResponse containing the output path and whether it ran in mock or real mode.
  Future<DenoiseApiResponse> denoiseImage(String inputImagePath, String task, String modelId) async {
    Uint8List imageBytes;
    String filename;

    try {
      if (kIsWeb) {
        // On Web, inputImagePath is a blob URL. Load its bytes via local GET request.
        final response = await http.get(Uri.parse(inputImagePath));
        imageBytes = response.bodyBytes;
        filename = 'upload.png';
      } else {
        final file = File(inputImagePath);
        if (!await file.exists()) {
          throw ModelException('Input image file does not exist at path: $inputImagePath');
        }
        imageBytes = await file.readAsBytes();
        filename = path.basename(file.path);
      }
    } catch (e) {
      if (e is ModelException) rethrow;
      throw ModelException('Failed to read input image data: $e');
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/restore'));
      
      // Pass task and modelId as form parameters
      request.fields['task'] = task;
      request.fields['model_id'] = modelId;

      // Determine proper image media type
      MediaType mediaType;
      final lowerFilename = filename.toLowerCase();
      if (lowerFilename.endsWith('.jpg') || lowerFilename.endsWith('.jpeg')) {
        mediaType = MediaType('image', 'jpeg');
      } else if (lowerFilename.endsWith('.webp')) {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'png');
      }

      // Attach the image bytes as a multipart file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: mediaType,
      );
      request.files.add(multipartFile);

      debugPrint('NafnetApiService: Uploading image to ${ApiConfig.baseUrl}/restore (${(imageBytes.length / 1024).toStringAsFixed(2)} KB, task: $task, model: $modelId)...');
      
      // Post the image file and await response with timeout
      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('NafnetApiService: Backend responded with status ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        
        // Safety check to ensure we didn't receive a disguised JSON error message instead of an image
        if (!contentType.contains('image/png') && !contentType.contains('application/octet-stream')) {
          try {
            final bodyJson = json.decode(response.body);
            if (bodyJson is Map && bodyJson['success'] == false) {
              throw ModelException(bodyJson['detail'] ?? bodyJson['error'] ?? 'Inference failed');
            }
          } catch (e) {
            if (e is ModelException) rethrow;
          }
        }
        
        // Extract inference mode (mock or real) and metrics from response headers
        final inferenceMode = response.headers['x-inference-mode'] ?? 'real';
        final inferenceTimeMs = double.tryParse(response.headers['x-inference-time-ms'] ?? '');
        final processingDevice = response.headers['x-processing-device'];
        final qualityScore = double.tryParse(response.headers['x-quality-score'] ?? '');
        final inputSizeBytes = int.tryParse(response.headers['x-input-size-bytes'] ?? '');
        final outputSizeBytes = int.tryParse(response.headers['x-output-size-bytes'] ?? '');
        final brightnessIn = double.tryParse(response.headers['x-brightness-in'] ?? '');
        final contrastIn = double.tryParse(response.headers['x-contrast-in'] ?? '');
        final contrastOut = double.tryParse(response.headers['x-contrast-out'] ?? '');
        final lapVarIn = double.tryParse(response.headers['x-lap-var-in'] ?? '');
        final lapVarOut = double.tryParse(response.headers['x-lap-var-out'] ?? '');
        final colorDistortion = response.headers['x-color-distortion'] == 'true';
        
        if (kIsWeb) {
          // On Web, encode bytes to Base64 data URL to render safely in browser
          final base64String = base64Encode(response.bodyBytes);
          final dataUrl = 'data:image/png;base64,$base64String';
          debugPrint('NafnetApiService: Received enhanced image. Converted to data URL. Mode: $inferenceMode');
          return DenoiseApiResponse(
            outputPath: dataUrl,
            inferenceMode: inferenceMode,
            inferenceTimeMs: inferenceTimeMs,
            processingDevice: processingDevice,
            qualityScore: qualityScore,
            inputSizeBytes: inputSizeBytes,
            outputSizeBytes: outputSizeBytes,
            brightnessIn: brightnessIn,
            contrastIn: contrastIn,
            contrastOut: contrastOut,
            lapVarIn: lapVarIn,
            lapVarOut: lapVarOut,
            colorDistortion: colorDistortion,
          );
        } else {
          // Write the returned bytes to a temporary local file on Native
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final outputFilename = 'denoised_$timestamp.png';
          final outputPath = path.join(tempDir.path, outputFilename);
          
          final outputFile = File(outputPath);
          await outputFile.writeAsBytes(response.bodyBytes);
          
          debugPrint('NafnetApiService: Received enhanced image. Cached locally at $outputPath. Mode: $inferenceMode');
          return DenoiseApiResponse(
            outputPath: outputPath,
            inferenceMode: inferenceMode,
            inferenceTimeMs: inferenceTimeMs,
            processingDevice: processingDevice,
            qualityScore: qualityScore,
            inputSizeBytes: inputSizeBytes,
            outputSizeBytes: outputSizeBytes,
            brightnessIn: brightnessIn,
            contrastIn: contrastIn,
            contrastOut: contrastOut,
            lapVarIn: lapVarIn,
            lapVarOut: lapVarOut,
            colorDistortion: colorDistortion,
          );
        }
      } else {
        // Read the structured error JSON from FastAPI if available
        String errorMessage = 'Lỗi máy chủ (${response.statusCode})';
        try {
          final errorBody = json.decode(response.body);
          if (errorBody is Map) {
            errorMessage = errorBody['detail'] ?? errorBody['error'] ?? errorMessage;
          }
        } catch (_) {
          if (response.statusCode == 400) {
            errorMessage = 'Yêu cầu không hợp lệ (400). Vui lòng kiểm tra lại ảnh hoặc tham số.';
          } else if (response.statusCode == 503) {
            errorMessage = 'Chưa tìm thấy checkpoint cho model này (503).';
          } else if (response.statusCode == 500) {
            errorMessage = 'Lỗi xử lý AI từ hệ thống (500).';
          } else if (response.statusCode == 413) {
            errorMessage = 'Kích thước ảnh vượt quá giới hạn cho phép (10MB).';
          }
        }
        
        throw ModelException(errorMessage, response.statusCode.toString());
      }
    } on SocketException catch (e) {
      debugPrint('NafnetApiService: Network socket exception: $e');
      throw ModelException(
        'Không thể kết nối đến máy chủ backend.\n\n'
        'Vui lòng kiểm tra xem:\n'
        '• Máy chủ backend đã được bật chưa.\n'
        '• Địa chỉ cấu hình trong ApiConfig có chính xác không.',
        'CONN_ERR'
      );
    } on TimeoutException catch (e) {
      debugPrint('NafnetApiService: Connection timed out: $e');
      throw ModelException(
        'Kết nối quá hạn. Quá trình xử lý ảnh mất quá nhiều thời gian (Giới hạn: 30 giây).',
        'TIMEOUT'
      );
    } on ModelException {
      rethrow;
    } catch (e) {
      debugPrint('NafnetApiService: Communication failure: $e');
      throw ModelException('Đã xảy ra lỗi khi giao tiếp với máy chủ: $e');
    }
  }
}
