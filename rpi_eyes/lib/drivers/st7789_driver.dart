import 'dart:typed_data';

import 'package:rpi_eyes/drivers/display_config.dart';

enum St7789Command {
  swReset(0x01),
  sleepOut(0x11),
  displayOn(0x29),
  columnAddressSet(0x2A),
  rowAddressSet(0x2B),
  memoryWrite(0x2C),
  memoryAccessControl(0x36),
  pixelFormat(0x3A),
  invertOn(0x21);

  const St7789Command(this.value);
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

abstract class St7789Driver {
  final int chipSelect;
  final int dcPin;
  final int resetPin;

  bool _initialized = false;

  St7789Driver({
    required this.chipSelect,
    required this.dcPin,
    required this.resetPin,
  });

  GpioPin get dcGpio;
  GpioPin get resetGpio;
  SpiDevice get spi;

  Future<void> initialize({bool skipReset = false}) async {
    if (_initialized) return;

    if (!skipReset) {
      await _hardwareReset();
    }
    await _initSequence();
    _initialized = true;
  }

  Future<void> _hardwareReset() async {
    resetGpio.write(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    resetGpio.write(false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    resetGpio.write(true);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  Future<void> _initSequence() async {
    _sendCommand(St7789Command.swReset);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    _sendCommand(St7789Command.sleepOut);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _sendCommand(St7789Command.pixelFormat, [0x55]);
    _sendCommand(St7789Command.memoryAccessControl, [0x00]);
    _sendCommand(St7789Command.invertOn);
    _sendCommand(St7789Command.displayOn);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  void _sendCommand(St7789Command command, [List<int>? data]) {
    dcGpio.write(false);
    spi.write(Uint8List.fromList([command.value]));

    if (data != null && data.isNotEmpty) {
      dcGpio.write(true);
      spi.write(Uint8List.fromList(data));
    }
  }

  void _setWindow(int x0, int y0, int x1, int y1) {
    _sendCommand(St7789Command.columnAddressSet, [
      (x0 >> 8) & 0xFF,
      x0 & 0xFF,
      (x1 >> 8) & 0xFF,
      x1 & 0xFF,
    ]);
    _sendCommand(St7789Command.rowAddressSet, [
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

    _setWindow(0, 0, DisplayConfig.width - 1, DisplayConfig.height - 1);

    dcGpio.write(false);
    spi.write(Uint8List.fromList([St7789Command.memoryWrite.value]));

    dcGpio.write(true);

    // Split buffer into chunks to avoid SPI transfer size limit
    for (
      var offset = 0;
      offset < rgb565Buffer.length;
      offset += _maxChunkSize
    ) {
      final end = (offset + _maxChunkSize).clamp(0, rgb565Buffer.length);
      final chunk = rgb565Buffer.sublist(offset, end);
      spi.write(chunk);
    }
  }

  void dispose() {
    dcGpio.dispose();
    resetGpio.dispose();
    spi.dispose();
  }
}

class MockSt7789Driver extends St7789Driver {
  MockSt7789Driver({
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
