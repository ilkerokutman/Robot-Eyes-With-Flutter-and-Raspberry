import 'dart:io';

class DisplayConfig {
  const DisplayConfig._();

  static const int width = 240;
  static const int height = 198;
  static const int bytesPerPixel = 2;
  static const int bufferSize = width * height * bytesPerPixel;

  // Pi 5 may need slower SPI speed - try 20MHz instead of 40MHz
  static const int spiSpeedHz = 20000000;
  static const int spiBus = 0;

  // CS: Pin 24 = CE0, Pin 26 = CE1
  static const int leftEyeChipSelect = 0; // CE0 (Pin 24)
  static const int rightEyeChipSelect = 1; // CE1 (Pin 26)

  // DC (Data/Command): Pin 18 = GPIO 24 (shared)
  static const int dcPin = 24;

  // Reset: Pin 22 = GPIO 25 (shared)
  static const int resetPin = 25;

  /// GPIO chip number - on Pi 5, gpiochip4 is a symlink to gpiochip0
  /// Both Pi 4 and Pi 5 use chip 0 for main GPIO
  static const int gpioChip = 0;

  /// Check if running on Pi 5 by looking for RP1 GPIO chips
  static bool get isPi5 => File('/dev/gpiochip10').existsSync();
}
