import 'dart:typed_data';

import 'package:dart_periphery/dart_periphery.dart';

import 'package:rpi_eyes/drivers/display_config.dart';
import 'package:rpi_eyes/drivers/gc9a01_driver.dart';

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

/// Shared GPIO manager for displays with common DC/Reset pins.
class SharedGpio {
  SharedGpio._();

  static SharedGpio? _instance;
  static SharedGpio get instance => _instance ??= SharedGpio._();

  GPIO? _dcGpio;
  GPIO? _resetGpio;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;

    try {
      print('SharedGpio: opening DC pin ${DisplayConfig.dcPin}');
      _dcGpio = GPIO(DisplayConfig.dcPin, GPIOdirection.gpioDirOut);
      print('SharedGpio: opening Reset pin ${DisplayConfig.resetPin}');
      _resetGpio = GPIO(DisplayConfig.resetPin, GPIOdirection.gpioDirOut);
      _initialized = true;
      print('SharedGpio initialized OK');
    } catch (e, st) {
      print('SharedGpio initialization FAILED: $e');
      print('SharedGpio stack trace: $st');
      rethrow;
    }
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

/// Real hardware implementation of the GC9A01 driver using `dart_periphery`.
///
/// Each display creates its own SPI instance on the same bus with a different
/// chip select:
///   - Display 1: SPI(0, 0, SPI_MODE_0, 40000000)
///   - Display 2: SPI(0, 1, SPI_MODE_0, 40000000)
class RealGc9a01Driver extends Gc9a01Driver {
  RealGc9a01Driver({
    required super.chipSelect,
    required super.dcPin,
    required super.resetPin,
  });

  late final SPI _spi;
  bool _spiInitialized = false;

  String get _name => 'GC9A01(CS$chipSelect)';

  void _initSpi() {
    if (_spiInitialized) return;

    try {
      print(
        '$_name opening SPI bus=${DisplayConfig.spiBus} '
        'cs=$chipSelect mode=0 speed=${DisplayConfig.spiSpeedHz}',
      );
      _spi = SPI(
        DisplayConfig.spiBus,
        chipSelect,
        SPImode.mode0,
        DisplayConfig.spiSpeedHz,
      );
      _spiInitialized = true;
      print('$_name SPI opened OK');
    } catch (e, st) {
      print('$_name SPI open FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  @override
  GpioPin get dcGpio {
    try {
      return RealGpioPin(SharedGpio.instance.dcGpio, ownsPin: false);
    } catch (e, st) {
      print('$_name dcGpio FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  @override
  GpioPin get resetGpio {
    try {
      return RealGpioPin(SharedGpio.instance.resetGpio, ownsPin: false);
    } catch (e, st) {
      print('$_name resetGpio FAILED: $e');
      print('$_name stack trace: $st');
      rethrow;
    }
  }

  @override
  SpiDevice get spi {
    _initSpi();
    return RealSpiDevice(_spi);
  }

  @override
  void dispose() {
    print('$_name disposing SPI');
    if (_spiInitialized) {
      try {
        _spi.dispose();
        print('$_name SPI disposed OK');
      } catch (e, st) {
        print('$_name SPI dispose FAILED: $e');
        print('$_name stack trace: $st');
      }
    }
  }
}
