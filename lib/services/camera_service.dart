// camera_service.dart
import 'dart:developer';
import 'package:camera/camera.dart';

class CameraService {
  static CameraController? controller;
  static bool isActive = false;

  /// Start camera preview
  static Future<bool> startPreview({Function(String)? onError}) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call("No cameras found");
        isActive = false;
        return false;
      }

      controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller!.initialize();
      isActive = true;
      return true; // ✅ indicate success
    } catch (e) {
      onError?.call(e.toString());
      isActive = false;
      return false; // ✅ indicate failure
    }
  }

  /// Stop camera preview
  static Future<void> stopPreview() async {
    try {
      await controller?.dispose();
    } catch (e) {
      log("Error stopping camera: $e");
    }
    controller = null;
    isActive = false;
  }

  /// Capture frame + detect emotion
  static Future<String?> captureAndAnalyzeEmotion() async {
    try {
      if (controller == null || !controller!.value.isInitialized) {
        return "No Camera";
      }

      // Capture a frame
      final XFile file = await controller!.takePicture();

      // TODO: Replace this with ML model or API
      // Simulated detection for now
      final moods = ["Happy", "Sad", "Angry", "Neutral", "Surprised"];
      moods.shuffle();
      return moods.first;
    } catch (e) {
      log("Emotion detection error: $e");
      return "Detection Failed";
    }
  }
}
