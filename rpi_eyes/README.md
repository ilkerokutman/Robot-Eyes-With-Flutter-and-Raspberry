# rpi_eyes

The eyes display application for the Robot Eyes project. Runs on Raspberry Pi and renders animated robot eyes to dual GC9A01 SPI round displays.

## Features

- Animated robot eyes with 9 emotion states
- Dual GC9A01 SPI round display support (240x240 each)
- WebSocket server for remote control
- UDP broadcast for auto-discovery
- Asynchronous blinking animation

## Entry Point

- `lib/main.dart` - Auto-detects platform: SPI mode on Raspberry Pi, desktop rendering elsewhere

## Build & Run

```bash
# Desktop/VNC mode
flutter run -d linux

# SPI display mode (on Raspberry Pi)
flutter build linux --release -t lib/main.dart
./build/linux/arm64/release/bundle/rpi_eyes
```

## Part of

This is part of the [Robot Eyes](../README.md) project.

## License

[MIT License](../LICENSE)
