import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PixelCapture {
  PixelCapture({required this.boundaryKey});

  final GlobalKey boundaryKey;

  Future<ui.Image?> capture({double pixelRatio = 1.0}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return null;
    }

    return boundary.toImage(pixelRatio: pixelRatio);
  }

  RenderRepaintBoundary? get renderBoundary {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary) {
      return boundary;
    }
    return null;
  }
}
