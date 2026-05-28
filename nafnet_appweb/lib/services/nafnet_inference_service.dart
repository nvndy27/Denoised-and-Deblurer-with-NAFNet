export 'nafnet_inference_service_stub.dart'
  if (dart.library.ffi) 'nafnet_inference_service_native.dart'
  if (dart.library.js_interop) 'nafnet_inference_service_web.dart';
