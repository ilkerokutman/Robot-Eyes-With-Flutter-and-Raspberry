import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/emotion_config.dart';
import 'package:rpi_eyes/app/core/enums.dart';
import 'package:rpi_eyes/app/widgets/eyelid.dart';
import 'package:rpi_eyes/app/widgets/pupil.dart';

class EyeWidget extends StatefulWidget {
  const EyeWidget({
    super.key,
    required this.side,
    required this.emotion,
    this.gaze = Alignment.center,
  });
  final EyeSide side;
  final Emotion emotion;
  final Alignment gaze;

  @override
  State<EyeWidget> createState() => _EyeWidgetState();
}

class _EyeWidgetState extends State<EyeWidget> with TickerProviderStateMixin {
  late AnimationController _emotionController;
  late AnimationController _blinkController;
  late AnimationController _gazeController;
  late EmotionConfig _currentConfig;
  late EmotionConfig _targetConfig;
  late Alignment _currentGaze;
  late Alignment _targetGaze;

  Timer? _blinkTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentConfig = EmotionConfig.forEmotion(widget.emotion, widget.side);
    _targetConfig = _currentConfig;
    _currentGaze = widget.gaze;
    _targetGaze = widget.gaze;

    _emotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _gazeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final config = EmotionConfig.forEmotion(widget.emotion, widget.side);
    final variance =
        _random.nextInt(config.blinkVarianceMs * 2) - config.blinkVarianceMs;
    final interval = config.blinkIntervalMs + variance;

    _blinkTimer = Timer(Duration(milliseconds: interval.clamp(500, 10000)), () {
      _blink();
    });
  }

  Future<void> _blink() async {
    if (!mounted) return;
    await _blinkController.forward();
    if (!mounted) return;
    await _blinkController.reverse();
    if (mounted) _scheduleNextBlink();
  }

  @override
  void didUpdateWidget(EyeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emotion != widget.emotion) {
      _currentConfig = EmotionConfig.lerp(
        _currentConfig,
        _targetConfig,
        _emotionController.value,
      );
      _targetConfig = EmotionConfig.forEmotion(widget.emotion, widget.side);
      _emotionController.forward(from: 0);
      _scheduleNextBlink();
    }
    if (oldWidget.gaze != widget.gaze) {
      _currentGaze = Alignment.lerp(
        _currentGaze,
        _targetGaze,
        _gazeController.value,
      )!;
      _targetGaze = widget.gaze;
      _gazeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _emotionController.dispose();
    _blinkController.dispose();
    _gazeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _emotionController,
        _blinkController,
        _gazeController,
      ]),
      builder: (context, child) {
        final config = EmotionConfig.lerp(
          _currentConfig,
          _targetConfig,
          Curves.easeInOut.transform(_emotionController.value),
        );

        final gaze = Alignment.lerp(
          _currentGaze,
          _targetGaze,
          Curves.easeOutCubic.transform(_gazeController.value),
        )!;

        final blinkValue = Curves.easeInOut.transform(_blinkController.value);
        final upperLid = max(config.upperLidTop, blinkValue * 0.52);
        final lowerLid = max(config.lowerLidBottom, blinkValue * 0.52);

        return Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Transform.scale(
              scaleX: 198 / 240,
              child: ClipOval(
                child: Container(
                  color: Colors.grey[900],
                  child: Stack(
                    children: [
                      Pupil(side: widget.side, config: config, gaze: gaze),
                      Eyelid(isUpper: false, closedAmount: upperLid),
                      Eyelid(isUpper: true, closedAmount: lowerLid),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
