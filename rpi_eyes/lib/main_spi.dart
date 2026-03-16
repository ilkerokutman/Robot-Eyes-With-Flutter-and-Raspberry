import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/screen/home_spi.dart';
import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/display_manager.dart';
import 'package:rpi_eyes/drivers/st7789_spi_driver.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final piVersion = DisplayConfig.isPi5 ? 'Pi 5' : 'Pi 4/earlier';
    print(
      'Detected: Raspberry $piVersion (GPIO chip ${DisplayConfig.gpioChip})',
    );
    print('Initializing SPI displays...');

    final displayManager = DisplayManager(
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

    print('Initializing display manager...');
    await displayManager.initialize();
    print('Display manager initialized successfully');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeSpiScreen(displayManager: displayManager),
      ),
    );
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print('Stack trace:\n$stackTrace');
  }
}
