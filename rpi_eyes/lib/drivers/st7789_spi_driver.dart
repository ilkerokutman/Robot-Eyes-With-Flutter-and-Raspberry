import 'dart:typed_data';

import 'package:dart_periphery/dart_periphery.dart';

import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/st7789_driver.dart';

class RealGpioPin implements GpioPin {
  RealGpioPin(this._pin, {this.ownsPin = true});

  final GPIO _pin;
  final bool ownsPin;

  @override
  void write(bool high) {
    _pin.write(high);
  }

  @override
  void dispose() {
    if (ownsPin) {
      _pin.dispose();
    }
  }
}

class RealSpiDevice implements SpiDevice {
  RealSpiDevice(this._spi);

  final SPI _spi;

  @override
  void write(Uint8List data) {
    _spi.transfer(data, false);
  }

  @override
  void dispose() {
    _spi.dispose();
  }
}

/// Shared GPIO manager for displays with common DC/Reset pins
class SharedGpio {
  SharedGpio._();

  static SharedGpio? _instance;
  static SharedGpio get instance => _instance ??= SharedGpio._();

  GPIO? _dcGpio;
  GPIO? _resetGpio;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    // Use GPIO chip number for Pi 5 compatibility
    // Pi 4: chip 0, Pi 5: chip 4
    final chip = DisplayConfig.gpioChip;
    _dcGpio = GPIO(DisplayConfig.dcPin, GPIOdirection.gpioDirOut, chip);
    _resetGpio = GPIO(DisplayConfig.resetPin, GPIOdirection.gpioDirOut, chip);
    _initialized = true;
  }

  GPIO get dcGpio {
    initialize();
    return _dcGpio!;
  }

  GPIO get resetGpio {
    initialize();
    return _resetGpio!;
  }

  void dispose() {
    _dcGpio?.dispose();
    _resetGpio?.dispose();
    _dcGpio = null;
    _resetGpio = null;
    _initialized = false;
    _instance = null;
  }
}

class RealSt7789Driver extends St7789Driver {
  RealSt7789Driver({
    required super.chipSelect,
    required super.dcPin,
    required super.resetPin,
  });

  late final SPI _spi;
  bool _spiInitialized = false;

  void _initSpi() {
    if (_spiInitialized) return;
    _spi = SPI(
      DisplayConfig.spiBus,
      chipSelect,
      SPImode.mode0,
      DisplayConfig.spiSpeedHz,
    );
    _spiInitialized = true;
  }

  @override
  GpioPin get dcGpio {
    return RealGpioPin(SharedGpio.instance.dcGpio, ownsPin: false);
  }

  @override
  GpioPin get resetGpio {
    return RealGpioPin(SharedGpio.instance.resetGpio, ownsPin: false);
  }

  @override
  SpiDevice get spi {
    _initSpi();
    return RealSpiDevice(_spi);
  }

  @override
  void dispose() {
    if (_spiInitialized) {
      _spi.dispose();
    }
  }
}
