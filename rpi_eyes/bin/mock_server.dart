import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

final emotions = [
  'idle',
  'curious',
  'happy',
  'angry',
  'frightened',
  'sad',
  'joyful',
  'bored',
  'friendly',
];

void main() async {
  final server = await HttpServer.bind('127.0.0.1', 5000);
  debugPrint('Mock WebSocket server running on ws://127.0.0.1:5000');
  debugPrint('Sending random emotion/gaze data every 3 seconds...');

  await for (final request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      debugPrint('Client connected');
      _handleClient(socket);
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('WebSocket connections only')
        ..close();
    }
  }
}

void _handleClient(WebSocket socket) {
  final random = Random();
  var emotionIndex = 0;

  final timer = Timer.periodic(const Duration(seconds: 3), (_) {
    emotionIndex = (emotionIndex + 1) % emotions.length;

    final data = {
      'emotion': emotions[emotionIndex],
      'gaze': {
        'x': (random.nextDouble() * 2 - 1).clamp(-1.0, 1.0),
        'y': (random.nextDouble() * 2 - 1).clamp(-1.0, 1.0),
      },
    };

    final json = jsonEncode(data);
    debugPrint('Sending: $json');
    socket.add(json);
  });

  socket.listen(
    (message) => debugPrint('Received: $message'),
    onDone: () {
      debugPrint('Client disconnected');
      timer.cancel();
    },
    onError: (error) {
      debugPrint('Error: $error');
      timer.cancel();
    },
  );
}
