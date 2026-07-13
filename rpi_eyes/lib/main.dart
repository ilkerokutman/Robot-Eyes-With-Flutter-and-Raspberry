import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'package:rpi_eyes/app/app.dart';
import 'package:rpi_eyes/app/screen/home_spi.dart';
import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/display_manager.dart';
import 'package:rpi_eyes/drivers/gc9a01_spi_driver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows) {
    await _runDesktop();
  } else if (Platform.isLinux) {
    await _runRaspberryPi();
  } else {
    await _runDesktop();
  }
}

Future<void> _diagnosticFill(DisplayManager manager) async {
  final colors = <(String, int, int)>[
    ('red', 0xF8, 0x00),
    ('green', 0x07, 0xE0),
    ('blue', 0x00, 0x1F),
  ];

  for (final color in colors) {
    final buffer = Uint8List(DisplayConfig.bufferSize);
    for (var i = 0; i < buffer.length; i += 2) {
      buffer[i] = color.$2;
      buffer[i + 1] = color.$3;
    }

    manager.leftDriver.drawBuffer(buffer);
    manager.rightDriver.drawBuffer(buffer);
    print('Diagnostic: both screens filled ${color.$1}');
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}

Future<void> _runDesktop() async {
  final packageInfo = await PackageInfo.fromPlatform();
  print('Robot Eyes v${packageInfo.version} | Desktop');

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(480, 240),
    center: true,
    skipTaskbar: false,
    fullScreen: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MainApp());
}

Future<void> _runRaspberryPi() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();

    // Detect platform and SPI availability
    final piVersion = DisplayConfig.isPi5 ? 'Pi 5' : 'Pi 4';
    DisplayManager? displayManager;
    bool spiAvailable = false;

    print('Robot Eyes v${packageInfo.version} | $piVersion | starting...');
    print('Initializing GC9A01 SPI displays...');

    // Attempt to initialize SPI displays
    try {
      displayManager = DisplayManager(
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
      await displayManager.initialize();

      // Temporary diagnostic: fill both screens red for 3 seconds.
      // Remove once displays are confirmed working.
      await _diagnosticFill(displayManager);

      spiAvailable = true;
    } catch (e, st) {
      // SPI initialization failed - continue with HDMI only
      print('SPI init error: $e\n$st');
      spiAvailable = false;
      displayManager = null;
    }

    // Print startup info
    final spiStatus = spiAvailable ? 'OK' : 'NOK';
    print('Robot Eyes v${packageInfo.version} | $piVersion | SPI: $spiStatus');

    // Run appropriate app
    if (spiAvailable && displayManager != null) {
      // Run with SPI display support
      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomeSpiScreen(displayManager: displayManager),
        ),
      );
    } else {
      // Run HDMI-only version
      runApp(const MainApp());
    }
  } catch (e, stackTrace) {
    print('ERROR: Failed to initialize Raspberry Pi app: $e');
    print('Stack trace: $stackTrace');
    // Fallback to HDMI-only
    runApp(const MainApp());
  }
}
