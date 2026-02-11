# rpi_eyes

The eyes display application for the Robot Eyes project. Runs on Raspberry Pi and renders animated robot eyes to dual ST7789 SPI displays.

## Features

- Animated robot eyes with 9 emotion states
- Dual ST7789 SPI display support (240x240 each)
- WebSocket server for remote control
- UDP broadcast for auto-discovery
- Asynchronous blinking animation

## Entry Points

- `lib/main.dart` - Desktop/VNC mode (standard Flutter rendering)
- `lib/main_spi.dart` - SPI display mode (renders to ST7789 displays)

## Build & Run

```bash
# Desktop/VNC mode
flutter run -d linux

# SPI display mode (on Raspberry Pi)
flutter build linux --release -t lib/main_spi.dart
./build/linux/arm64/release/bundle/rpi_eyes
```

## Part of

This is part of the [Robot Eyes](../README.md) project.

## License

[MIT License](../LICENSE)
