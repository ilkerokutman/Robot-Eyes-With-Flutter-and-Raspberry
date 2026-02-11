import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/enums.dart';
import 'package:rpi_eyes/app/widgets/eye_widget.dart';
import 'package:rpi_eyes/services/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.port = 5050});

  final int port;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Emotion _currentEmotion = Emotion.idle;
  Alignment _gaze = Alignment.center;

  HttpServer? _server;
  final List<WebSocket> _clients = [];

  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  static const int _broadcastPort = 5001;
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _startServer();
    _startBroadcast();
  }

  @override
  void dispose() {
    _stopServer();
    _stopBroadcast();
    super.dispose();
  }

  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind('0.0.0.0', widget.port);
      debugPrint(
        'Eyes WebSocket server running on ws://0.0.0.0:${widget.port}',
      );

      await for (final request in _server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _clients.add(socket);
          debugPrint('Control client connected');
          _handleClient(socket);
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Eyes WebSocket Server - Connect via ws://')
            ..close();
        }
      }
    } catch (e) {
      debugPrint('Server error: $e');
    }
  }

  void _handleClient(WebSocket socket) {
    socket.listen(
      (message) {
        try {
          final json = jsonDecode(message as String) as Map<String, dynamic>;
          final data = RobotData.fromJson(json);
          setState(() {
            _currentEmotion = data.emotion;
            _gaze = data.gaze;
          });
        } catch (e) {
          debugPrint('Parse error: $e');
        }
      },
      onDone: () {
        _clients.remove(socket);
        debugPrint('Control client disconnected');
      },
      onError: (error) {
        _clients.remove(socket);
        debugPrint('Client error: $error');
      },
    );
  }

  Future<void> _stopServer() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
  }

  Future<void> _startBroadcast() async {
    try {
      _localIp = await _getLocalIp();
      if (_localIp == null) {
        debugPrint('Could not determine local IP');
        return;
      }

      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket!.broadcastEnabled = true;

      final message = jsonEncode({
        'service': 'rpi_eyes',
        'ip': _localIp,
        'port': widget.port,
      });

      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        try {
          _udpSocket?.send(
            utf8.encode(message),
            InternetAddress('255.255.255.255'),
            _broadcastPort,
          );
        } catch (e) {
          debugPrint('Broadcast error: $e');
        }
      });

      debugPrint('Broadcasting on UDP port $_broadcastPort: $message');
    } catch (e) {
      debugPrint('Failed to start broadcast: $e');
    }
  }

  void _stopBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: EyeWidget(
              side: EyeSide.left,
              emotion: _currentEmotion,
              gaze: _gaze,
            ),
          ),
          Expanded(
            child: EyeWidget(
              side: EyeSide.right,
              emotion: _currentEmotion,
              gaze: _gaze,
            ),
          ),
        ],
      ),
    );
  }
}
