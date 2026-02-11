import 'dart:typed_data';

class Rgb565Converter {
  const Rgb565Converter._();

  static Uint8List fromRgba8888(Uint8List rgba, int width, int height) {
    final rgb565 = Uint8List(width * height * 2);
    var j = 0;

    for (var i = 0; i < rgba.length; i += 4) {
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];

      final r5 = (r >> 3) & 0x1F;
      final g6 = (g >> 2) & 0x3F;
      final b5 = (b >> 3) & 0x1F;

      final rgb565Value = (r5 << 11) | (g6 << 5) | b5;

      rgb565[j++] = (rgb565Value >> 8) & 0xFF;
      rgb565[j++] = rgb565Value & 0xFF;
    }

    return rgb565;
  }

  static Uint8List fromRgba8888Scaled(
    Uint8List rgba,
    int srcWidth,
    int srcHeight,
    int dstWidth,
    int dstHeight,
  ) {
    final rgb565 = Uint8List(dstWidth * dstHeight * 2);

    final xRatio = srcWidth / dstWidth;
    final yRatio = srcHeight / dstHeight;

    var j = 0;
    for (var y = 0; y < dstHeight; y++) {
      for (var x = 0; x < dstWidth; x++) {
        final srcX = (x * xRatio).toInt();
        final srcY = (y * yRatio).toInt();
        final srcIndex = (srcY * srcWidth + srcX) * 4;

        final r = rgba[srcIndex];
        final g = rgba[srcIndex + 1];
        final b = rgba[srcIndex + 2];

        final r5 = (r >> 3) & 0x1F;
        final g6 = (g >> 2) & 0x3F;
        final b5 = (b >> 3) & 0x1F;

        final rgb565Value = (r5 << 11) | (g6 << 5) | b5;

        rgb565[j++] = (rgb565Value >> 8) & 0xFF;
        rgb565[j++] = rgb565Value & 0xFF;
      }
    }

    return rgb565;
  }
}
