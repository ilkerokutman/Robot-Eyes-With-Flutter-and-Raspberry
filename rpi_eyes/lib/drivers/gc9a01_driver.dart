import 'dart:typed_data';

import 'package:rpi_eyes/drivers/display_config.dart';

/// Command set for the GC9A01 240x240 round LCD controller.
enum Gc9a01Command {
  swReset(0x01),
  sleepIn(0x10),
  sleepOut(0x11),
  partialModeOn(0x12),
  normalModeOn(0x13),
  invertOff(0x20),
  invertOn(0x21),
  displayOff(0x28),
  displayOn(0x29),
  columnAddressSet(0x2A),
  rowAddressSet(0x2B),
  memoryWrite(0x2C),
  partialArea(0x30),
  pixelFormat(0x3A),
  memoryAccessControl(0x36),
  tearingEffectLineOn(0x35);

  const Gc9a01Command(this.value);
  final int value;
}

abstract class GpioPin {
  void write(bool high);
  void dispose();
}

abstract class SpiDevice {
  void write(Uint8List data);
  void dispose();
}

/// Base driver for GC9A01 round LCDs.
abstract class Gc9a01Driver {
  final int chipSelect;
  final int dcPin;
  final int resetPin;

  bool _initialized = false;

  Gc9a01Driver({
    required this.chipSelect,
    required this.dcPin,
    required this.resetPin,
  });

  String get _name => 'GC9A01(CS$chipSelect)';

  GpioPin get dcGpio;
  GpioPin get resetGpio;
  SpiDevice get spi;

  Future<void> initialize({bool skipReset = false}) async {
    if (_initialized) {
      print('$_name already initialized');
      return;
    }

    print('$_name initializing...');
    try {
      if (!skipReset) {
        print('$_name hardware reset');
        await _hardwareReset();
      } else {
        print('$_name skipping hardware reset');
      }
      print('$_name sending init sequence');
      await _initSequence();
      _initialized = true;
      print('$_name initialization complete');
    } catch (e, st) {
      print('$_name initialization FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  Future<void> _hardwareReset() async {
    try {
      resetGpio.write(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      resetGpio.write(false);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      resetGpio.write(true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      print('$_name reset pulse finished');
    } catch (e, st) {
      print('$_name reset pulse FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  /// GC9A01 power-up / configuration sequence.
  /// Based on the widely-used TFT_eSPI / Waveshare reference sequence.
  Future<void> _initSequence() async {
    try {
      _sendCommand(Gc9a01Command.swReset);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      _sendCommandRaw(0xEF);
      _sendCommandRaw(0xEB, [0x14]);

      _sendCommandRaw(0xFE);
      _sendCommandRaw(0xEF);

      _sendCommandRaw(0xEB, [0x14]);

      _sendCommandRaw(0x84, [0x40]);
      _sendCommandRaw(0x85, [0xFF]);
      _sendCommandRaw(0x86, [0xFF]);
      _sendCommandRaw(0x87, [0xFF]);
      _sendCommandRaw(0x88, [0x0A]);
      _sendCommandRaw(0x89, [0x21]);
      _sendCommandRaw(0x8A, [0x00]);
      _sendCommandRaw(0x8B, [0x80]);
      _sendCommandRaw(0x8C, [0x01]);
      _sendCommandRaw(0x8D, [0x01]);
      _sendCommandRaw(0x8E, [0xFF]);
      _sendCommandRaw(0x8F, [0xFF]);

      _sendCommandRaw(0xB6, [0x00, 0x20]);

      // 16 bits per pixel, RGB565.
      _sendCommand(Gc9a01Command.pixelFormat, [0x05]);

      _sendCommandRaw(0x90, [0x08, 0x08, 0x08, 0x08]);
      _sendCommandRaw(0xBD, [0x06]);
      _sendCommandRaw(0xBC, [0x00]);
      _sendCommandRaw(0xFF, [0x60, 0x01, 0x04]);

      _sendCommandRaw(0xC3, [0x13]);
      _sendCommandRaw(0xC4, [0x13]);
      _sendCommandRaw(0xC9, [0x22]);
      _sendCommandRaw(0xBE, [0x11]);
      _sendCommandRaw(0xE1, [0x10, 0x0E]);
      _sendCommandRaw(0xDF, [0x21, 0x0C, 0x02]);

      _sendCommandRaw(0xF0, [0x45, 0x09, 0x08, 0x08, 0x26, 0x2A]);
      _sendCommandRaw(0xF1, [0x43, 0x70, 0x72, 0x36, 0x37, 0x6F]);
      _sendCommandRaw(0xF2, [0x45, 0x09, 0x08, 0x08, 0x26, 0x2A]);
      _sendCommandRaw(0xF3, [0x43, 0x70, 0x72, 0x36, 0x37, 0x6F]);

      _sendCommandRaw(0xED, [0x1B, 0x0B]);
      _sendCommandRaw(0xAE, [0x77]);
      _sendCommandRaw(0xCD, [0x63]);

      _sendCommandRaw(0x70, [
        0x07,
        0x07,
        0x04,
        0x0E,
        0x0F,
        0x09,
        0x07,
        0x08,
        0x03,
      ]);
      _sendCommandRaw(0xE8, [0x34]);

      _sendCommandRaw(0x62, [
        0x18,
        0x0D,
        0x71,
        0xED,
        0x70,
        0x70,
        0x18,
        0x0F,
        0x71,
        0xEF,
        0x70,
        0x70,
      ]);
      _sendCommandRaw(0x63, [
        0x18,
        0x11,
        0x71,
        0xF1,
        0x70,
        0x70,
        0x18,
        0x13,
        0x71,
        0xF3,
        0x70,
        0x70,
      ]);
      _sendCommandRaw(0x64, [0x28, 0x29, 0xF1, 0x01, 0xF1, 0x00, 0x07]);
      _sendCommandRaw(0x66, [
        0x3C,
        0x00,
        0xCD,
        0x67,
        0x45,
        0x45,
        0x10,
        0x00,
        0x00,
        0x00,
      ]);
      _sendCommandRaw(0x67, [
        0x00,
        0x3C,
        0x00,
        0x00,
        0x00,
        0x01,
        0x54,
        0x10,
        0x32,
        0x98,
      ]);
      _sendCommandRaw(0x74, [0x10, 0x85, 0x80, 0x00, 0x00, 0x4E, 0x00]);
      _sendCommandRaw(0x98, [0x3E, 0x07]);

      // Final wakeup: tearing effect, inversion, sleep out, display on.
      // No MADCTL — leave the controller default orientation.
      _sendCommand(Gc9a01Command.tearingEffectLineOn);
      _sendCommand(Gc9a01Command.invertOn);

      _sendCommand(Gc9a01Command.sleepOut);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      _sendCommand(Gc9a01Command.displayOn);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      print('$_name init sequence sent successfully');
    } catch (e, st) {
      print('$_name init sequence FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  void _sendCommand(Gc9a01Command command, [List<int>? data]) {
    _sendCommandRaw(command.value, data);
  }

  void _sendCommandRaw(int command, [List<int>? data]) {
    try {
      dcGpio.write(false);
      spi.write(Uint8List.fromList([command]));

      if (data != null && data.isNotEmpty) {
        dcGpio.write(true);
        spi.write(Uint8List.fromList(data));
      }
    } catch (e, st) {
      print(
        '$_name sendCommand 0x${command.toRadixString(16).padLeft(2, '0')} '
        'FAILED: $e',
      );
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  void _setWindow(int x0, int y0, int x1, int y1) {
    _sendCommand(Gc9a01Command.columnAddressSet, [
      (x0 >> 8) & 0xFF,
      x0 & 0xFF,
      (x1 >> 8) & 0xFF,
      x1 & 0xFF,
    ]);
    _sendCommand(Gc9a01Command.rowAddressSet, [
      (y0 >> 8) & 0xFF,
      y0 & 0xFF,
      (y1 >> 8) & 0xFF,
      y1 & 0xFF,
    ]);
  }

  static const int _maxChunkSize = 4096;

  void drawBuffer(Uint8List rgb565Buffer) {
    if (!_initialized) {
      throw StateError('Driver not initialized. Call initialize() first.');
    }

    print(
      '$_name drawBuffer: ${rgb565Buffer.length} bytes '
      '(${DisplayConfig.width}x${DisplayConfig.height}@16bpp)',
    );

    try {
      _setWindow(0, 0, DisplayConfig.width - 1, DisplayConfig.height - 1);

      dcGpio.write(false);
      spi.write(Uint8List.fromList([Gc9a01Command.memoryWrite.value]));

      dcGpio.write(true);

      // Split buffer into chunks to avoid SPI transfer size limit.
      var chunks = 0;
      for (
        var offset = 0;
        offset < rgb565Buffer.length;
        offset += _maxChunkSize
      ) {
        final end = (offset + _maxChunkSize).clamp(0, rgb565Buffer.length);
        final chunk = rgb565Buffer.sublist(offset, end);
        spi.write(chunk);
        chunks++;
      }
      print('$_name drawBuffer complete ($chunks chunks)');
    } catch (e, st) {
      print('$_name drawBuffer FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  void dispose() {
    dcGpio.dispose();
    resetGpio.dispose();
    spi.dispose();
  }
}

class MockGc9a01Driver extends Gc9a01Driver {
  MockGc9a01Driver({
    required super.chipSelect,
    required super.dcPin,
    required super.resetPin,
  });

  @override
  GpioPin get dcGpio => _MockGpioPin();

  @override
  GpioPin get resetGpio => _MockGpioPin();

  @override
  SpiDevice get spi => _MockSpiDevice();
}

class _MockGpioPin implements GpioPin {
  @override
  void write(bool high) {}

  @override
  void dispose() {}
}

class _MockSpiDevice implements SpiDevice {
  @override
  void write(Uint8List data) {}

  @override
  void dispose() {}
}
