import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:rpi_eyes/services/robot_data.dart';

class WebSocketClient extends ChangeNotifier {
  WebSocketClient({this.url = 'ws://127.0.0.1:5000'});

  final String url;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  RobotData _data = RobotData.idle;
  bool _connected = false;

  RobotData get data => _data;
  bool get connected => _connected;

  Future<void> connect() async {
    _reconnectTimer?.cancel();

    try {
      _socket = await WebSocket.connect(url);
      _connected = true;
      notifyListeners();

      _subscription = _socket!.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      _data = RobotData.fromJson(json);
      notifyListeners();
    } catch (e) {
      debugPrint('WebSocket parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('WebSocket error: $error');
    _connected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _socket?.close();
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
