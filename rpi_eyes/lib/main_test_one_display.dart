import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/gc9a01_spi_driver.dart';

/// Standalone test entry point for a single GC9A01 display.
///
/// Wire one display directly to the Pi:
///   VCC  -> Pin 2 or 4  (5V)
///   GND  -> Pin 6 or 9  (GND)
///   DIN  -> Pin 19      (MOSI / GPIO 10)
///   CLK  -> Pin 23      (SCLK / GPIO 11)
///   CS   -> Pin 24      (CE0 / GPIO 8)
///   DC   -> Pin 18      (GPIO 24)
///   RST  -> Pin 22      (GPIO 25)
///   BL   -> Pin 1 or 17 (3.3V)
///
/// Build and run on the Pi:
///   flutter build linux --release -t lib/main_test_one_display.dart
///   ./build/linux/arm64/release/bundle/rpi_eyes
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final packageInfo = await PackageInfo.fromPlatform();
  print('Robot Eyes single-display test v${packageInfo.version}');

  final driver = RealGc9a01Driver(
    chipSelect: DisplayConfig.leftEyeChipSelect, // CE0 / Pin 24
    dcPin: DisplayConfig.dcPin, // GPIO 24 / Pin 18
    resetPin: DisplayConfig.resetPin, // GPIO 25 / Pin 22
  );

  try {
    print('Initializing single display...');
    await driver.initialize();
    print('Display initialized');
  } catch (e, st) {
    print('Display init FAILED: $e');
    print(st);
    return;
  }

  const colors = <(String, int, int)>[
    ('red', 0xF8, 0x00),
    ('green', 0x07, 0xE0),
    ('blue', 0x00, 0x1F),
    ('white', 0xFF, 0xFF),
    ('black', 0x00, 0x00),
  ];

  for (final color in colors) {
    final buffer = Uint8List(DisplayConfig.bufferSize);
    for (var i = 0; i < buffer.length; i += 2) {
      buffer[i] = color.$2;
      buffer[i + 1] = color.$3;
    }

    print('Filling screen ${color.$1}...');
    driver.drawBuffer(buffer);
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  print('Test complete. Screen should have cycled colors.');
  print('Press Ctrl+C to exit.');
}
