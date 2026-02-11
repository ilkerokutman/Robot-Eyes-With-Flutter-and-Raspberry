import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/enums.dart';

class EmotionConfig {
  const EmotionConfig({
    required this.pupilScale,
    required this.pupilColor,
    required this.glowColor,
    required this.glowIntensity,
    required this.offsetX,
    required this.offsetY,
    required this.upperLidTop,
    required this.lowerLidBottom,
    this.pupilSquash = 1.0,
    this.blinkIntervalMs = 3000,
    this.blinkVarianceMs = 1500,
  });

  final double pupilScale;
  final Color pupilColor;
  final Color glowColor;
  final double glowIntensity;
  final double offsetX;
  final double offsetY;
  final double upperLidTop;
  final double lowerLidBottom;
  final double pupilSquash;
  final int blinkIntervalMs;
  final int blinkVarianceMs;

  static EmotionConfig forEmotion(Emotion emotion, EyeSide side) {
    return switch (emotion) {
      Emotion.idle => const EmotionConfig(
        pupilScale: 1.0,
        pupilColor: Colors.cyanAccent,
        glowColor: Colors.cyanAccent,
        glowIntensity: 0.5,
        offsetX: 0,
        offsetY: 0,
        upperLidTop: 0,
        lowerLidBottom: 0,
        blinkIntervalMs: 3500,
        blinkVarianceMs: 2000,
      ),
      Emotion.curious => EmotionConfig(
        pupilScale: 1.3,
        pupilColor: Colors.cyanAccent,
        glowColor: Colors.cyanAccent,
        glowIntensity: 0.7,
        offsetX: side == EyeSide.left ? 0.15 : 0.15,
        offsetY: -0.1,
        upperLidTop: 0,
        lowerLidBottom: 0,
        blinkIntervalMs: 2500,
        blinkVarianceMs: 1000,
      ),
      Emotion.happy => const EmotionConfig(
        pupilScale: 1.1,
        pupilColor: Colors.cyanAccent,
        glowColor: Colors.cyanAccent,
        glowIntensity: 0.8,
        offsetX: 0,
        offsetY: 0.05,
        upperLidTop: 0.25,
        lowerLidBottom: 0,
        blinkIntervalMs: 2000,
        blinkVarianceMs: 800,
      ),
      Emotion.angry => const EmotionConfig(
        pupilScale: 0.7,
        pupilColor: Colors.redAccent,
        glowColor: Colors.red,
        glowIntensity: 0.9,
        offsetX: 0,
        offsetY: 0,
        upperLidTop: 0.35,
        lowerLidBottom: 0,
        pupilSquash: 0.85,
        blinkIntervalMs: 5000,
        blinkVarianceMs: 2000,
      ),
      Emotion.frightened => const EmotionConfig(
        pupilScale: 1.5,
        pupilColor: Colors.white,
        glowColor: Colors.white,
        glowIntensity: 0.6,
        offsetX: 0,
        offsetY: 0,
        upperLidTop: 0,
        lowerLidBottom: 0,
        blinkIntervalMs: 1500,
        blinkVarianceMs: 500,
      ),
      Emotion.sad => const EmotionConfig(
        pupilScale: 0.9,
        pupilColor: Colors.lightBlueAccent,
        glowColor: Colors.lightBlue,
        glowIntensity: 0.3,
        offsetX: 0,
        offsetY: 0.15,
        upperLidTop: 0.2,
        lowerLidBottom: 0,
        blinkIntervalMs: 4000,
        blinkVarianceMs: 1500,
      ),
      Emotion.joyful => const EmotionConfig(
        pupilScale: 1.2,
        pupilColor: Colors.yellowAccent,
        glowColor: Colors.yellow,
        glowIntensity: 1.0,
        offsetX: 0,
        offsetY: 0,
        upperLidTop: 0.3,
        lowerLidBottom: 0.2,
        blinkIntervalMs: 1800,
        blinkVarianceMs: 600,
      ),
      Emotion.bored => const EmotionConfig(
        pupilScale: 0.85,
        pupilColor: Colors.grey,
        glowColor: Colors.grey,
        glowIntensity: 0.2,
        offsetX: 0,
        offsetY: 0.1,
        upperLidTop: 0.4,
        lowerLidBottom: 0,
        blinkIntervalMs: 6000,
        blinkVarianceMs: 3000,
      ),
      Emotion.friendly => EmotionConfig(
        pupilScale: 1.15,
        pupilColor: Colors.greenAccent,
        glowColor: Colors.green,
        glowIntensity: 0.6,
        offsetX: side == EyeSide.left ? -0.08 : 0.08,
        offsetY: 0,
        upperLidTop: 0.15,
        lowerLidBottom: 0,
        blinkIntervalMs: 2500,
        blinkVarianceMs: 1000,
      ),
    };
  }

  static EmotionConfig lerp(EmotionConfig a, EmotionConfig b, double t) {
    return EmotionConfig(
      pupilScale: lerpDouble(a.pupilScale, b.pupilScale, t)!,
      pupilColor: Color.lerp(a.pupilColor, b.pupilColor, t)!,
      glowColor: Color.lerp(a.glowColor, b.glowColor, t)!,
      glowIntensity: lerpDouble(a.glowIntensity, b.glowIntensity, t)!,
      offsetX: lerpDouble(a.offsetX, b.offsetX, t)!,
      offsetY: lerpDouble(a.offsetY, b.offsetY, t)!,
      upperLidTop: lerpDouble(a.upperLidTop, b.upperLidTop, t)!,
      lowerLidBottom: lerpDouble(a.lowerLidBottom, b.lowerLidBottom, t)!,
      pupilSquash: lerpDouble(a.pupilSquash, b.pupilSquash, t)!,
    );
  }
}
