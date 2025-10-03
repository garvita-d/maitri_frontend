import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import 'package:camera/camera.dart';

class CameraEmotionScreen extends StatefulWidget {
  const CameraEmotionScreen({super.key});

  @override
  State<CameraEmotionScreen> createState() => _CameraEmotionScreenState();
}

class _CameraEmotionScreenState extends State<CameraEmotionScreen> {
  String _mood = "Detecting...";

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    await CameraService.startPreview(
      onError: (msg) => debugPrint("Camera error: $msg"),
    );
    setState(() {});
    _detectLoop();
  }

  // Continuously detect mood every few seconds
  Future<void> _detectLoop() async {
    while (mounted && CameraService.isActive) {
      final mood = await CameraService.captureAndAnalyzeEmotion();
      if (!mounted) return;

      setState(() {
        if (mood == null || mood.isEmpty || mood == "Detection Failed") {
          _mood = "No face detected";
        } else {
          _mood = mood;
        }
      });

      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  void dispose() {
    CameraService.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CameraService.controller;

    return Scaffold(
      appBar: AppBar(title: const Text("Mood Detection")),
      body: controller?.value.isInitialized != true
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Actual CameraPreview
                CameraPreview(controller!),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Mood: $_mood",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
