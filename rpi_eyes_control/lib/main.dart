import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const ControlApp());
}

class ControlApp extends StatelessWidget {
  const ControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyes Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const ControlScreen(),
    );
  }
}

enum Emotion {
  idle,
  curious,
  happy,
  angry,
  frightened,
  sad,
  joyful,
  bored,
  friendly,
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final TextEditingController _hostController = TextEditingController(
    text: '127.0.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '5050',
  );

  WebSocket? _socket;
  bool _connected = false;
  bool _connecting = false;

  Emotion _currentEmotion = Emotion.idle;
  Alignment _gaze = Alignment.center;

  Timer? _sendTimer;

  RawDatagramSocket? _udpSocket;
  bool _discovering = false;
  final List<Map<String, dynamic>> _discoveredServers = [];
  static const int _broadcastPort = 5001;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _disconnect();
    _stopDiscovery();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _broadcastPort,
      );
      setState(() => _discovering = true);

      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final json = jsonDecode(message) as Map<String, dynamic>;
              if (json['service'] == 'rpi_eyes') {
                _onServerDiscovered(json);
              }
            } catch (e) {
              debugPrint('Discovery parse error: $e');
            }
          }
        }
      });

      debugPrint('Listening for eyes servers on UDP port $_broadcastPort');
    } catch (e) {
      debugPrint('Failed to start discovery: $e');
      setState(() => _discovering = false);
    }
  }

  void _onServerDiscovered(Map<String, dynamic> server) {
    final ip = server['ip'] as String?;
    final port = server['port'] as int?;
    if (ip == null || port == null) return;

    final exists = _discoveredServers.any(
      (s) => s['ip'] == ip && s['port'] == port,
    );

    if (!exists) {
      setState(() {
        _discoveredServers.add(server);
      });
      debugPrint('Discovered eyes server: $ip:$port');
    }

    if (!_connected && !_connecting && _discoveredServers.length == 1) {
      _hostController.text = ip;
      _portController.text = port.toString();
    }
  }

  void _stopDiscovery() {
    _udpSocket?.close();
    _udpSocket = null;
    _discovering = false;
  }

  void _selectServer(Map<String, dynamic> server) {
    _hostController.text = server['ip'] as String;
    _portController.text = (server['port'] as int).toString();
    setState(() {});
  }

  Future<void> _connect() async {
    if (_connecting || _connected) return;

    setState(() => _connecting = true);

    try {
      final url = 'ws://${_hostController.text}:${_portController.text}';
      _socket = await WebSocket.connect(url);
      setState(() {
        _connected = true;
        _connecting = false;
      });

      _socket!.listen(
        (message) {},
        onDone: () {
          setState(() => _connected = false);
        },
        onError: (error) {
          setState(() => _connected = false);
        },
      );

      _startSendLoop();
    } catch (e) {
      setState(() => _connecting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  void _disconnect() {
    _sendTimer?.cancel();
    _socket?.close();
    _socket = null;
    setState(() => _connected = false);
  }

  void _startSendLoop() {
    _sendTimer?.cancel();
    _sendTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _sendState();
    });
  }

  void _sendState() {
    if (_socket == null || !_connected) return;

    final data = {
      'emotion': _currentEmotion.name,
      'gaze': {'x': _gaze.x, 'y': _gaze.y},
    };

    _socket!.add(jsonEncode(data));
  }

  void _cycleEmotion(int direction) {
    final emotions = Emotion.values;
    final currentIndex = emotions.indexOf(_currentEmotion);
    final newIndex = (currentIndex + direction) % emotions.length;
    setState(() => _currentEmotion = emotions[newIndex]);
    _sendState();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eyes Control'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              _connected ? Icons.wifi : Icons.wifi_off,
              color: _connected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isPortrait ? _buildPortraitLayout() : _buildLandscapeLayout(),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildConnectionPanel(),
        const SizedBox(height: 16),
        Expanded(flex: 2, child: _buildGazePanel()),
        const SizedBox(height: 16),
        Expanded(flex: 3, child: _buildEmotionPanel()),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        _buildConnectionPanel(),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildEmotionPanel()),
              const SizedBox(width: 16),
              Expanded(child: _buildGazePanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_discoveredServers.isNotEmpty && !_connected) ...[
            Row(
              children: [
                Icon(
                  Icons.radar,
                  size: 16,
                  color: Colors.green.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Discovered (${_discoveredServers.length}):',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _discoveredServers.map((server) {
                final ip = server['ip'] as String;
                final port = server['port'] as int;
                final isSelected =
                    _hostController.text == ip &&
                    _portController.text == port.toString();
                return GestureDetector(
                  onTap: () => _selectServer(server),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: Colors.green)
                          : null,
                    ),
                    child: Text(
                      '$ip:$port',
                      style: TextStyle(
                        color: isSelected ? Colors.green : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    labelText: 'Host',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _discovering
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : null,
                  ),
                  enabled: !_connected,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  enabled: !_connected,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _connected ? _disconnect : _connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _connected ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: _connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_connected ? 'Disconnect' : 'Connect'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emotion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _cycleEmotion(-1),
                    icon: const Icon(Icons.chevron_left, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    width: 90,
                    alignment: Alignment.center,
                    child: Text(
                      _currentEmotion.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _cycleEmotion(1),
                    icon: const Icon(Icons.chevron_right, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: Emotion.values.map((emotion) {
                final isSelected = emotion == _currentEmotion;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentEmotion = emotion);
                    _sendState();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.cyanAccent.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.cyanAccent, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emotion.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.cyanAccent : Colors.white70,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGazePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gaze',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _gaze = Alignment.center);
                  _sendState();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_gaze.x.toStringAsFixed(1)}, ${_gaze.y.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;
                return Center(
                  child: GestureDetector(
                    onPanStart: (details) {
                      _updateGazeFromPosition(details.localPosition, size);
                    },
                    onPanUpdate: (details) {
                      _updateGazeFromPosition(details.localPosition, size);
                    },
                    onDoubleTap: () {
                      setState(() => _gaze = Alignment.center);
                      _sendState();
                    },
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Align(
                            alignment: _gaze,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateGazeFromPosition(Offset position, double size) {
    final center = size / 2;
    final x = ((position.dx - center) / center).clamp(-1.0, 1.0);
    final y = ((position.dy - center) / center).clamp(-1.0, 1.0);
    setState(() => _gaze = Alignment(x, y));
  }
}
