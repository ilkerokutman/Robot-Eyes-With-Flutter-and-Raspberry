import 'dart:math';
import 'dart:typed_data';

import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/display_manager.dart';
import 'package:rpi_eyes/drivers/gc9a01_spi_driver.dart';

/// Standalone example for initializing and testing the dual GC9A01 displays.
///
/// Run on a Raspberry Pi 4 after enabling SPI (`spi0-2cs` overlay).
/// This file is not part of the normal Flutter app flow and can be used
/// directly from a small `main()` in a test harness or command-line target.
class DisplayTestExample {
  DisplayTestExample() {
    _manager = DisplayManager(
      leftDriver: RealGc9a01Driver(
        chipSelect: DisplayConfig.leftEyeChipSelect,
        dcPin: DisplayConfig.dcPin,
        resetPin: DisplayConfig.resetPin,
      ),
      rightDriver: RealGc9a01Driver(
        chipSelect: DisplayConfig.rightEyeChipSelect,
        dcPin: DisplayConfig.dcPin,
        resetPin: DisplayConfig.resetPin,
      ),
    );
  }

  late final DisplayManager _manager;

  Future<void> initialize() async {
    await _manager.initialize();
  }

  /// Convert an RGB triplet to a big-endian RGB565 byte pair.
  static Uint8List rgbToRgb565(int r, int g, int b) {
    final r5 = (r >> 3) & 0x1F;
    final g6 = (g >> 2) & 0x3F;
    final b5 = (b >> 3) & 0x1F;
    final value = (r5 << 11) | (g6 << 5) | b5;
    return Uint8List.fromList([(value >> 8) & 0xFF, value & 0xFF]);
  }

  /// Fill both screens with a solid [r, g, b] color.
  void fillColor(int r, int g, int b) {
    final color = rgbToRgb565(r, g, b);
    final buffer = Uint8List(DisplayConfig.bufferSize);

    for (var i = 0; i < buffer.length; i += 2) {
      buffer[i] = color[0];
      buffer[i + 1] = color[1];
    }

    _manager.leftDriver.drawBuffer(buffer);
    _manager.rightDriver.drawBuffer(buffer);
  }

  /// Draw a simple colored square in the center of both round displays.
  void drawCenterSquare(int r, int g, int b) {
    final color = rgbToRgb565(r, g, b);
    final background = rgbToRgb565(0, 0, 0);
    final buffer = Uint8List(DisplayConfig.bufferSize);

    // Fill background.
    for (var i = 0; i < buffer.length; i += 2) {
      buffer[i] = background[0];
      buffer[i + 1] = background[1];
    }

    // Draw a 100x100 centered square.
    const squareSize = 100;
    final startX = (DisplayConfig.width - squareSize) ~/ 2;
    final startY = (DisplayConfig.height - squareSize) ~/ 2;

    for (var y = startY; y < startY + squareSize; y++) {
      for (var x = startX; x < startX + squareSize; x++) {
        final offset = (y * DisplayConfig.width + x) * 2;
        buffer[offset] = color[0];
        buffer[offset + 1] = color[1];
      }
    }

    _manager.leftDriver.drawBuffer(buffer);
    _manager.rightDriver.drawBuffer(buffer);
  }

  /// Draw a colored circle in the center of both displays.
  void drawCenterCircle(int r, int g, int b) {
    final color = rgbToRgb565(r, g, b);
    final background = rgbToRgb565(0, 0, 0);
    final buffer = Uint8List(DisplayConfig.bufferSize);

    const radius = 80;
    final centerX = DisplayConfig.width ~/ 2;
    final centerY = DisplayConfig.height ~/ 2;

    for (var y = 0; y < DisplayConfig.height; y++) {
      for (var x = 0; x < DisplayConfig.width; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        final offset = (y * DisplayConfig.width + x) * 2;
        final pixel = distance <= radius ? color : background;
        buffer[offset] = pixel[0];
        buffer[offset + 1] = pixel[1];
      }
    }

    _manager.leftDriver.drawBuffer(buffer);
    _manager.rightDriver.drawBuffer(buffer);
  }

  void dispose() {
    _manager.dispose();
  }
}
