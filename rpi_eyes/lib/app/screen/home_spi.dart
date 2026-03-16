import 'dart:async';

import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/enums.dart';
import 'package:rpi_eyes/app/widgets/eye_widget.dart';
import 'package:rpi_eyes/drivers/drivers.dart';

class HomeSpiScreen extends StatefulWidget {
  const HomeSpiScreen({super.key, required this.displayManager});

  final DisplayManager displayManager;

  @override
  State<HomeSpiScreen> createState() => _HomeSpiScreenState();
}

class _HomeSpiScreenState extends State<HomeSpiScreen> {
  Emotion _currentEmotion = Emotion.idle;
  final Alignment _gaze = Alignment.center;

  final GlobalKey _leftEyeKey = GlobalKey();
  final GlobalKey _rightEyeKey = GlobalKey();

  Timer? _renderTimer;
  Timer? _autoCycleTimer;

  @override
  void initState() {
    super.initState();
    _startRenderLoop();
    _startAutoCycle();
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    _autoCycleTimer?.cancel();
    super.dispose();
  }

  void _startRenderLoop() {
    _renderTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _captureAndSend(),
    );
  }

  void _startAutoCycle() {
    _autoCycleTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _cycleEmotion(1);
    });
  }

  Future<void> _captureAndSend() async {
    try {
      final leftCapture = PixelCapture(boundaryKey: _leftEyeKey);
      final rightCapture = PixelCapture(boundaryKey: _rightEyeKey);

      final leftBoundary = leftCapture.renderBoundary;
      final rightBoundary = rightCapture.renderBoundary;

      if (leftBoundary != null && rightBoundary != null) {
        await widget.displayManager.drawFromRenderObjects(
          leftBoundary,
          rightBoundary,
        );
      }
    } catch (e, st) {
      print('ERROR in _captureAndSend: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }

  void _cycleEmotion(int direction) {
    final emotions = Emotion.values;
    final currentIndex = emotions.indexOf(_currentEmotion);
    final newIndex = (currentIndex + direction) % emotions.length;
    setState(() => _currentEmotion = emotions[newIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _leftEyeKey,
              child: EyeWidget(
                side: EyeSide.left,
                emotion: _currentEmotion,
                gaze: _gaze,
              ),
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: _rightEyeKey,
              child: EyeWidget(
                side: EyeSide.right,
                emotion: _currentEmotion,
                gaze: _gaze,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
