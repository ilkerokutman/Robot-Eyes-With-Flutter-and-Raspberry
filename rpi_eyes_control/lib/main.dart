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
      title: 'Göz Kontrol',
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

extension EmotionTR on Emotion {
  String get trName {
    switch (this) {
      case Emotion.idle:
        return 'Boşta';
      case Emotion.curious:
        return 'Meraklı';
      case Emotion.happy:
        return 'Mutlu';
      case Emotion.angry:
        return 'Sinirli';
      case Emotion.frightened:
        return 'Korkmuş';
      case Emotion.sad:
        return 'Üzgün';
      case Emotion.joyful:
        return 'Neşeli';
      case Emotion.bored:
        return 'Sıkılmış';
      case Emotion.friendly:
        return 'Dostça';
    }
  }
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final TextEditingController _hostController = TextEditingController(
    text: '192.168.0.108',
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
              debugPrint('Keşif ayrıştırma hatası: $e');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Keşif başlatılamadı: $e');
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
      setState(() => _discoveredServers.add(server));
    }
  }

  void _stopDiscovery() {
    _udpSocket?.close();
    _udpSocket = null;
  }

  void _showConnectionDialog() {
    if (_connected) {
      _showDisconnectDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Gözlere Bağlan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_discoveredServers.isNotEmpty) ...[
              const Text(
                'Bulunan sunucular:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ..._discoveredServers.map((server) => ListTile(
                    dense: true,
                    title: Text(
                      '${server['ip']}:${server['port']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _hostController.text = server['ip'] as String;
                      _portController.text = (server['port'] as int).toString();
                    },
                  )),
              const Divider(),
            ],
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Sunucu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: _connecting
                ? null
                : () {
                    Navigator.pop(context);
                    _connect();
                  },
            child: _connecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Bağlan'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Bağlantıyı Kes?'),
        content: const Text('Gözlerden bağlantıyı kesmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnect();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bağlantıyı Kes'),
          ),
        ],
      ),
    );
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
        onDone: () => setState(() => _connected = false),
        onError: (_) => setState(() => _connected = false),
      );

      _startSendLoop();
    } catch (e) {
      setState(() => _connecting = false);
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

  void _setEmotion(Emotion emotion) {
    setState(() => _currentEmotion = emotion);
    _sendState();
  }

  void _updateGaze(Alignment gaze) {
    setState(() => _gaze = gaze);
    _sendState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Göz Kontrol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showConnectionDialog,
            icon: Icon(
              _connected ? Icons.wifi : Icons.wifi_off,
              color: _connected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(child: _buildGazePanel()),
              const SizedBox(height: 16),
              Expanded(child: _buildEmotionPanel()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGazePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bakış',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _updateGaze(Alignment.center),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
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
          const SizedBox(height: 16),
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
                    onDoubleTap: () => _updateGaze(Alignment.center),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(51),
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
                                color: Colors.white.withAlpha(77),
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
                                    color: Colors.cyanAccent.withAlpha(128),
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
    _updateGaze(Alignment(x, y));
  }

  Widget _buildEmotionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Duygu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: Emotion.values.map((emotion) {
                final isSelected = emotion == _currentEmotion;
                return GestureDetector(
                  onTap: () => _setEmotion(emotion),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.cyanAccent.withAlpha(77)
                          : Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.cyanAccent, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emotion.trName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
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
}
