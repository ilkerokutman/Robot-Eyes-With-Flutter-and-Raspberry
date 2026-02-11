class DisplayConfig {
  const DisplayConfig._();

  static const int width = 240;
  static const int height = 198;
  static const int bytesPerPixel = 2;
  static const int bufferSize = width * height * bytesPerPixel;

  static const int spiSpeedHz = 40000000;
  static const int spiBus = 0;

  // CS: Pin 24 = CE0, Pin 26 = CE1
  static const int leftEyeChipSelect = 0; // CE0 (Pin 24)
  static const int rightEyeChipSelect = 1; // CE1 (Pin 26)

  // DC (Data/Command): Pin 18 = GPIO 24 (shared)
  static const int dcPin = 24;

  // Reset: Pin 22 = GPIO 25 (shared)
  static const int resetPin = 25;
}
