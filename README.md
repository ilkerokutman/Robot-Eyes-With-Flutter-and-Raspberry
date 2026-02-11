# Robot Eyes

[Türkçe için tıklayın](README_TR.md)

A Flutter-based robot eyes display system for Raspberry Pi with ST7789 SPI displays.


## Demo Videos

<video src="docs/video1.mp4" controls width="400"></video>

<video src="docs/video2.mp4" controls width="400"></video>

## Overview

This project consists of two Flutter applications:

- **rpi_eyes** - The eyes display application that runs on a Raspberry Pi and renders animated robot eyes to dual ST7789 SPI displays
- **rpi_eyes_control** - A control application (desktop/mobile) that connects to the eyes app via WebSocket to control emotions and gaze direction

## Features

- 9 emotion states: idle, curious, happy, angry, frightened, sad, joyful, bored, friendly
- Smooth gaze control with joystick interface
- Asynchronous blinking animation
- WebSocket communication between control app and eyes app
- UDP broadcast discovery for automatic connection
- Cross-platform control app (macOS, iOS, Android)

## Hardware Requirements

### Display
- 2x [0.96inch IPS ST7789 Module](https://www.lcdwiki.com/0.96inch_IPS_ST7789_Module) (240x240 resolution)
- Raspberry Pi (tested on Pi 4/5)

### Wiring


![Robot Eyes Demo](docs/connection.png)

![GPIO Pinout](docs/GPIO.png)

| Wire Color | Function | Connectivity | Raspberry Pi Pin |
|------------|----------|--------------|------------------|
| Yellow | SCL (Clock) | Shared | Pin 23 (SCLK) |
| Green | SDA (Data) | Shared | Pin 19 (MOSI) |
| Blue | RES (Reset) | Shared | Pin 22 (GPIO 25) |
| White | DC (Data/Cmd) | Shared | Pin 18 (GPIO 24) |
| Red | GND | Shared | Pin 6 (GND) |
| Black | VCC | Shared | Pin 2 (5V) |
| Purple | BLK | Shared | Pin 1 (3.3V) |
| Orange | CS (Select) | **UNIQUE** | Disp 1 → Pin 24 (CE0) / Disp 2 → Pin 26 (CE1) |

> **Note:** All signals except CS (Chip Select) are shared between both displays. Each display requires its own CS line for independent control.

## Software Setup

### Prerequisites

1. Enable SPI on Raspberry Pi:
   ```bash
   sudo raspi-config
   # Navigate to: Interface Options → SPI → Enable
   ```

2. Enable dual chip select:
   Add to `/boot/config.txt`:
   ```
   dtparam=spi=on
   dtoverlay=spi0-2cs
   ```

3. Add user to GPIO/SPI groups:
   ```bash
   sudo usermod -aG gpio,spi $USER
   ```

4. Reboot the Pi

### Building the Eyes App (on Raspberry Pi)

```bash
cd rpi_eyes
flutter pub get
flutter build linux --release -t lib/main_spi.dart
```

### Running the Eyes App

```bash
./build/linux/arm64/release/bundle/rpi_eyes
```

For VNC/desktop mode (without SPI displays):
```bash
flutter run -d linux
```

### Building the Control App

**macOS:**
```bash
cd rpi_eyes_control
flutter build macos --release
```

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Usage

1. Start the eyes app on the Raspberry Pi
2. Launch the control app on your phone or computer
3. The control app will automatically discover the eyes app via UDP broadcast
4. Tap to connect, then use the joystick to control gaze and buttons to change emotions

## Network Ports

- **WebSocket:** 5050 (eyes server)
- **UDP Discovery:** 5001 (broadcast)

## Project Structure

```
eyes/
├── rpi_eyes/                 # Eyes display application
│   ├── lib/
│   │   ├── app/              # UI components
│   │   ├── drivers/          # SPI/ST7789 drivers
│   │   ├── models/           # Data models
│   │   ├── services/         # WebSocket services
│   │   ├── main.dart         # Desktop entry point
│   │   └── main_spi.dart     # SPI display entry point
│   └── ...
├── rpi_eyes_control/         # Control application
│   ├── lib/
│   │   └── main.dart         # Control app UI
│   └── ...
└── docs/                     # Documentation assets
```

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgments

- Display module: [0.96inch IPS ST7789 Module](https://www.lcdwiki.com/0.96inch_IPS_ST7789_Module)
- Built with [Flutter](https://flutter.dev)
