import 'dart:io';

import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

import 'package:rpi_eyes/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows) {
    await _runDesktop();
  } else if (Platform.isLinux) {
    await _runRaspberryPi();
  } else {
    await _runDesktop();
  }
}

Future<void> _runDesktop() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(480, 240),
    center: true,
    skipTaskbar: false,
    fullScreen: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MainApp());
}

Future<void> _runRaspberryPi() async {
  // On Linux/Pi, run the same app but fullscreen
  // SPI display mode requires running main_spi.dart instead
  runApp(const MainApp());
}
