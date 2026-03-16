import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'package:rpi_eyes/app/app.dart';
import 'package:rpi_eyes/app/screen/home_spi.dart';
import 'package:rpi_eyes/core/version.dart';
import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/display_manager.dart';
import 'package:rpi_eyes/drivers/st7789_spi_driver.dart';

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

Future<void> _runDesktop() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: const Size(480, 240),
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
    // Detect platform and SPI availability
    final piVersion = DisplayConfig.isPi5 ? 'Pi 5' : 'Pi 4';
    DisplayManager? displayManager;
    bool spiAvailable = false;

    // Attempt to initialize SPI displays
    try {
      displayManager = DisplayManager(
        leftDriver: RealSt7789Driver(
          chipSelect: DisplayConfig.leftEyeChipSelect,
          dcPin: DisplayConfig.dcPin,
          resetPin: DisplayConfig.resetPin,
        ),
        rightDriver: RealSt7789Driver(
          chipSelect: DisplayConfig.rightEyeChipSelect,
          dcPin: DisplayConfig.dcPin,
          resetPin: DisplayConfig.resetPin,
        ),
      );
      await displayManager.initialize();
      spiAvailable = true;
    } catch (e, st) {
      // SPI initialization failed - continue with HDMI only
      print('SPI init error: $e\n$st');
      spiAvailable = false;
      displayManager = null;
    }

    // Print startup info
    final spiStatus = spiAvailable ? 'OK' : 'NOK';
    print('Robot Eyes v${AppVersion.full} | $piVersion | SPI: $spiStatus');

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
