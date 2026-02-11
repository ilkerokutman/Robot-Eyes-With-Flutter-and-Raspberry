import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/enums.dart';

class RobotData {
  const RobotData({
    required this.emotion,
    required this.gaze,
  });

  final Emotion emotion;
  final Alignment gaze;

  factory RobotData.fromJson(Map<String, dynamic> json) {
    final emotionStr = json['emotion'] as String? ?? 'idle';
    final emotion = Emotion.values.firstWhere(
      (e) => e.name == emotionStr,
      orElse: () => Emotion.idle,
    );

    final gazeJson = json['gaze'] as Map<String, dynamic>?;
    final gaze = gazeJson != null
        ? Alignment(
            (gazeJson['x'] as num?)?.toDouble() ?? 0.0,
            (gazeJson['y'] as num?)?.toDouble() ?? 0.0,
          )
        : Alignment.center;

    return RobotData(emotion: emotion, gaze: gaze);
  }

  Map<String, dynamic> toJson() => {
        'emotion': emotion.name,
        'gaze': {'x': gaze.x, 'y': gaze.y},
      };

  static const RobotData idle = RobotData(
    emotion: Emotion.idle,
    gaze: Alignment.center,
  );
}
