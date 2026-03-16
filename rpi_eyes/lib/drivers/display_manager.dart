import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/rgb565_converter.dart';
import 'package:rpi_eyes/drivers/st7789_driver.dart';

class DisplayManager {
  DisplayManager({required this.leftDriver, required this.rightDriver});

  final St7789Driver leftDriver;
  final St7789Driver rightDriver;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    print('========================================');
    print('Robot Eyes v1.0.0');
    print('========================================');
    print('Initializing left display (CE${leftDriver.chipSelect})...');
    await leftDriver.initialize();
    print('Left display initialized');

    print('Initializing right display (CE${rightDriver.chipSelect})...');
    await rightDriver.initialize(skipReset: true);
    print('Right display initialized');

    _initialized = true;
  }

  Future<void> drawFromRenderObjects(
    RenderRepaintBoundary leftBoundary,
    RenderRepaintBoundary rightBoundary,
  ) async {
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
  }

  Future<void> drawFromImages(ui.Image leftImage, ui.Image rightImage) async {
    final leftBytes = await _imageToRgb565(leftImage);
    final rightBytes = await _imageToRgb565(rightImage);

    leftDriver.drawBuffer(leftBytes);
    rightDriver.drawBuffer(rightBytes);
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
