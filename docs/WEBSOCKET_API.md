# Robot Eyes WebSocket API Documentation

This document describes the WebSocket API for controlling the Robot Eyes display remotely. Any device or application can use this API to control the eyes.

## Overview

The Robot Eyes application runs a WebSocket server that accepts connections from control clients. Once connected, clients can send commands to change the emotion and gaze direction of the eyes.

## Connection

### WebSocket Endpoint

```
ws://<IP_ADDRESS>:5050
```

**Default Port:** 5050

**Example:**
```
ws://192.168.0.108:5050
```

### Server Discovery (Optional)

The Robot Eyes app broadcasts its presence via UDP on port 5001. Broadcast message format:

```json
{
  "service": "rpi_eyes",
  "ip": "192.168.0.108",
  "port": 5050,
  "version": "2.1.0"
}
```

Listen on UDP port 5001 to discover available eye servers on your network.

## Protocol

### Message Format

All messages are JSON-encoded strings sent over the WebSocket connection.

### Command Structure

```json
{
  "emotion": "<emotion_name>",
  "gaze": {
    "x": <float>,
    "y": <float>
  }
}
```

### Fields

| Field | Type | Range | Description |
|-------|------|-------|-------------|
| `emotion` | String | See list below | The emotional state of the eyes |
| `gaze.x` | Float | -1.0 to 1.0 | Horizontal gaze direction (-1 = left, 0 = center, 1 = right) |
| `gaze.y` | Float | -1.0 to 1.0 | Vertical gaze direction (-1 = up, 0 = center, 1 = down) |

### Available Emotions

| Emotion Name | Description |
|--------------|-------------|
| `idle` | Neutral, default state |
| `curious` | Curious expression |
| `happy` | Happy expression |
| `angry` | Angry expression |
| `frightened` | Scared expression |
| `sad` | Sad expression |
| `joyful` | Joyful expression |
| `bored` | Bored expression |
| `friendly` | Friendly expression |

## Example Commands

### Center Gaze, Idle Emotion
```json
{
  "emotion": "idle",
  "gaze": {
    "x": 0.0,
    "y": 0.0
  }
}
```

### Look Right, Happy
```json
{
  "emotion": "happy",
  "gaze": {
    "x": 0.8,
    "y": 0.0
  }
}
```

### Look Up-Left, Angry
```json
{
  "emotion": "angry",
  "gaze": {
    "x": -0.5,
    "y": -0.5
  }
}
```

### Full Control Example
```json
{
  "emotion": "curious",
  "gaze": {
    "x": 0.3,
    "y": -0.2
  }
}
```

## Code Examples

### Python Example

```python
import asyncio
import json
import websockets

async def control_eyes():
    uri = "ws://192.168.0.108:5050"
    
    async with websockets.connect(uri) as websocket:
        # Send happy emotion, looking right
        command = {
            "emotion": "happy",
            "gaze": {"x": 0.8, "y": 0.0}
        }
        await websocket.send(json.dumps(command))
        
        # Wait a moment
        await asyncio.sleep(2)
        
        # Change to angry, looking left
        command = {
            "emotion": "angry",
            "gaze": {"x": -0.8, "y": 0.0}
        }
        await websocket.send(json.dumps(command))

asyncio.run(control_eyes())
```

### JavaScript (Node.js) Example

```javascript
const WebSocket = require('ws');

const ws = new WebSocket('ws://192.168.0.108:5050');

ws.on('open', () => {
  // Send happy emotion
  ws.send(JSON.stringify({
    emotion: 'happy',
    gaze: { x: 0.5, y: 0.0 }
  }));
  
  setTimeout(() => {
    // Change to sad
    ws.send(JSON.stringify({
      emotion: 'sad',
      gaze: { x: -0.3, y: 0.2 }
    }));
  }, 2000);
});
```

### JavaScript (Browser) Example

```javascript
const ws = new WebSocket('ws://192.168.0.108:5050');

ws.onopen = () => {
  console.log('Connected to Robot Eyes');
  
  // Send control command
  ws.send(JSON.stringify({
    emotion: 'curious',
    gaze: { x: 0.5, y: -0.2 }
  }));
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};
```

### Dart/Flutter Example

```dart
import 'dart:convert';
import 'dart:io';

void controlEyes() async {
  final ws = await WebSocket.connect('ws://192.168.0.108:5050');
  
  // Send command
  final command = {
    'emotion': 'happy',
    'gaze': {'x': 0.5, 'y': 0.0}
  };
  
  ws.add(jsonEncode(command));
  
  // Keep connection alive with periodic updates
  Timer.periodic(Duration(milliseconds: 100), (timer) {
    ws.add(jsonEncode(command));
  });
}
```

## Update Rate

The eyes update at 50ms (20fps) internally. To ensure smooth animation:

- **Recommended:** Send updates at 100ms intervals (10Hz)
- **Maximum:** Send updates at 50ms intervals (20Hz)
- **Minimum:** Send updates at 500ms intervals for responsive control

## Error Handling

The server silently ignores malformed JSON messages. If your command doesn't work:

1. Verify JSON syntax is valid
2. Check emotion name is in the allowed list
3. Ensure gaze x/y values are between -1.0 and 1.0
4. Confirm WebSocket connection is established

## Troubleshooting

### Cannot Connect
- Verify the Robot Eyes app is running on the Pi
- Check IP address and port are correct
- Ensure both devices are on the same network
- Check firewall settings allow port 5050

### Commands Not Working
- Verify JSON format matches specification exactly
- Check emotion names are lowercase
- Ensure gaze values are valid floats
- Try reconnecting the WebSocket

### Connection Drops
The server doesn't send keep-alive messages. If your client disconnects:
- Implement automatic reconnection
- Send periodic commands to keep connection alive
- Check network stability

## Version History

- **v2.1.0** - Current API with WebSocket control
- **v2.0.0** - Initial WebSocket implementation

## License

This API is open for any device or application to use. No authentication required.
