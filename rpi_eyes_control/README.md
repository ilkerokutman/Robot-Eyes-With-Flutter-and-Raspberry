# rpi_eyes_control

The control application for the Robot Eyes project. Connects to the eyes app via WebSocket to control emotions and gaze direction.

## Features

- Cross-platform (macOS, iOS, Android)
- WebSocket client for real-time control
- UDP discovery for automatic connection
- Touch-friendly joystick for gaze control
- Emotion selector with 9 states
- Responsive portrait/landscape layouts

## Platforms

- macOS
- iOS
- Android

## Build & Run

```bash
# macOS
flutter build macos --release

# Android
flutter build apk --release

# iOS
flutter build ios --release

# Run in development
flutter run
```

## Part of

This is part of the [Robot Eyes](../README.md) project.

## License

[MIT License](../LICENSE)
