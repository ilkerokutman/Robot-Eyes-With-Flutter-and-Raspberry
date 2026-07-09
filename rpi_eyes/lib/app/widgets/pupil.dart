import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/emotion_config.dart';
import 'package:rpi_eyes/app/core/enums.dart';

class Pupil extends StatelessWidget {
  const Pupil({
    super.key,
    required this.side,
    required this.config,
    this.gaze = Alignment.center,
  });
  final EyeSide side;
  final EmotionConfig config;
  final Alignment gaze;

  Widget _buildPupilContent(double pupilSize) {
    return switch (config.pupilShape) {
      PupilShape.heart => Icon(
        Icons.favorite,
        color: config.pupilColor,
        size: pupilSize * 0.9,
      ),
      PupilShape.questionMark => Text(
        '?',
        style: TextStyle(
          color: config.pupilColor,
          fontSize: pupilSize * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
      PupilShape.dollarSign => Text(
        '\$',
        style: TextStyle(
          color: config.pupilColor,
          fontSize: pupilSize * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
      PupilShape.circle => Container(
        width: pupilSize,
        height: pupilSize,
        decoration: BoxDecoration(
          color: config.pupilColor,
          shape: BoxShape.circle,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final eyeSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final basePupilSize = eyeSize * 0.42;
        final pupilSize = basePupilSize * config.pupilScale;
        final glintSize = pupilSize * 0.12;
        final glintOffset = pupilSize * 0.15;

        final maxOffset = (eyeSize - pupilSize) / 2 * 0.6;
        final emotionOffsetX = config.offsetX * maxOffset;
        final emotionOffsetY = config.offsetY * maxOffset;
        final gazeOffsetX = -gaze.x * maxOffset;
        final gazeOffsetY = gaze.y * maxOffset;
        final offsetX = emotionOffsetX + gazeOffsetX;
        final offsetY = emotionOffsetY + gazeOffsetY;

        final glow = BoxShadow(
          color: config.glowColor.withValues(alpha: config.glowIntensity),
          blurRadius: 20,
          spreadRadius: 5,
        );

        return Center(
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.scale(
              scaleY: config.pupilSquash,
              child: Container(
                width: pupilSize,
                height: pupilSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [glow],
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildPupilContent(pupilSize),
                    if (config.pupilShape == PupilShape.circle)
                      Positioned(
                        top: glintOffset,
                        left: glintOffset * 1.2,
                        child: Container(
                          width: glintSize,
                          height: glintSize,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
