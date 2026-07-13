import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/gc9a01_driver.dart';
import 'package:rpi_eyes/drivers/rgb565_converter.dart';

class DisplayManager {
  DisplayManager({required this.leftDriver, required this.rightDriver});

  final Gc9a01Driver leftDriver;
  final Gc9a01Driver rightDriver;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      print('DisplayManager already initialized');
      return;
    }

    print('DisplayManager: initializing left eye');
    await leftDriver.initialize();
    print('DisplayManager: initializing right eye');
    await rightDriver.initialize(skipReset: true);

    _initialized = true;
    print('DisplayManager: initialized');
  }

  Future<void> drawFromRenderObjects(
    RenderRepaintBoundary leftBoundary,
    RenderRepaintBoundary rightBoundary,
  ) async {
    try {
      final leftImage = await leftBoundary.toImage(
        pixelRatio: DisplayConfig.width / leftBoundary.size.width,
      );
      final rightImage = await rightBoundary.toImage(
        pixelRatio: DisplayConfig.width / rightBoundary.size.width,
      );

      final leftBytes = await _imageToRgb565(leftImage);
      final rightBytes = await _imageToRgb565(rightImage);

      leftDriver.drawBuffer(leftBytes);
      rightDriver.drawBuffer(rightBytes);

      leftImage.dispose();
      rightImage.dispose();
    } catch (e, st) {
      print('ERROR in drawFromRenderObjects: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> drawFromImages(ui.Image leftImage, ui.Image rightImage) async {
    try {
      final leftBytes = await _imageToRgb565(leftImage);
      final rightBytes = await _imageToRgb565(rightImage);

      leftDriver.drawBuffer(leftBytes);
      rightDriver.drawBuffer(rightBytes);
    } catch (e, st) {
      print('ERROR in drawFromImages: $e');
      print('Stack trace: $st');
      rethrow;
    }
  }

  Future<Uint8List> _imageToRgb565(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Failed to get image byte data');
    }

    final rgba = byteData.buffer.asUint8List();

    if (image.width == DisplayConfig.width &&
        image.height == DisplayConfig.height) {
      return Rgb565Converter.fromRgba8888(
        rgba,
        DisplayConfig.width,
        DisplayConfig.height,
      );
    }

    return Rgb565Converter.fromRgba8888Scaled(
      rgba,
      image.width,
      image.height,
      DisplayConfig.width,
      DisplayConfig.height,
    );
  }

  void dispose() {
    leftDriver.dispose();
    rightDriver.dispose();
  }
}
