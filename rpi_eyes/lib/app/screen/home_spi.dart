import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:rpi_eyes/app/core/enums.dart';
import 'package:rpi_eyes/app/widgets/eye_widget.dart';
import 'package:rpi_eyes/drivers/drivers.dart';
import 'package:rpi_eyes/services/robot_data.dart';

class HomeSpiScreen extends StatefulWidget {
  const HomeSpiScreen({
    super.key,
    required this.displayManager,
    this.port = 5050,
  });

  final DisplayManager displayManager;
  final int port;

  @override
  State<HomeSpiScreen> createState() => _HomeSpiScreenState();
}

class _HomeSpiScreenState extends State<HomeSpiScreen> {
  Emotion _currentEmotion = Emotion.idle;
  Alignment _gaze = Alignment.center;

  final GlobalKey _leftEyeKey = GlobalKey();
  final GlobalKey _rightEyeKey = GlobalKey();

  Timer? _renderTimer;

  HttpServer? _server;
  final List<WebSocket> _clients = [];

  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  static const int _broadcastPort = 5001;
  String? _localIp;

  @override
  void initState() {
    super.initState();
    _startRenderLoop();
    _startServer();
    _startBroadcast();
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    _stopServer();
    _stopBroadcast();
    super.dispose();
  }

  void _startRenderLoop() {
    _renderTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _captureAndSend(),
    );
  }

  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind('0.0.0.0', widget.port);

      // Wait for IP detection and print it
      await Future.delayed(const Duration(milliseconds: 500));
      if (_localIp != null) {
        print('WebSocket server ready at ws://$_localIp:${widget.port}');
      } else {
        print('WebSocket server ready at port ${widget.port}');
      }

      await for (final request in _server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          _clients.add(socket);
          _handleClient(socket);
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Eyes WebSocket Server - Connect via ws://')
            ..close();
        }
      }
    } catch (e) {
      print('Server error: $e');
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
          print('Parse error: $e');
        }
      },
      onDone: () {
        _clients.remove(socket);
      },
      onError: (error) {
        _clients.remove(socket);
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
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              addr.address.startsWith('192.168.')) {
            _localIp = addr.address;
            break;
          }
        }
      }

      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (_localIp == null) return;

        final message = jsonEncode({
          'service': 'rpi_eyes',
          'ip': _localIp,
          'port': widget.port,
          'version': '2.2.0',
        });

        _udpSocket!.send(
          utf8.encode(message),
          InternetAddress('255.255.255.255'),
          _broadcastPort,
        );
      });
    } catch (e) {
      print('Broadcast error: $e');
    }
  }

  void _stopBroadcast() {
    _broadcastTimer?.cancel();
    _udpSocket?.close();
  }

  Future<void> _captureAndSend() async {
    try {
      final leftCapture = PixelCapture(boundaryKey: _leftEyeKey);
      final rightCapture = PixelCapture(boundaryKey: _rightEyeKey);

      final leftBoundary = leftCapture.renderBoundary;
      final rightBoundary = rightCapture.renderBoundary;

      if (leftBoundary != null && rightBoundary != null) {
        await widget.displayManager.drawFromRenderObjects(
          leftBoundary,
          rightBoundary,
        );
      } else {
        print(
          'WARNING: Render boundaries null - left: $leftBoundary, right: $rightBoundary',
        );
      }
    } catch (e, st) {
      print('ERROR in _captureAndSend: $e');
      print('Stack trace: $st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _leftEyeKey,
              child: EyeWidget(
                side: EyeSide.left,
                emotion: _currentEmotion,
                gaze: _gaze,
              ),
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              key: _rightEyeKey,
              child: EyeWidget(
                side: EyeSide.right,
                emotion: _currentEmotion,
                gaze: _gaze,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
