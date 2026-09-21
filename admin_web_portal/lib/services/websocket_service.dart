import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketService {
  late io.Socket socket;
  final List<Function(dynamic)> _listeners = [];

  void addListener(Function(dynamic) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(dynamic) listener) {
    _listeners.remove(listener);
  }

  void initSocket() {
    // Replace with your production URL or use localhost for dev
    socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Connected to WebSocket server');
    });

    socket.on('update_received', (data) {
      debugPrint('Received real-time update: $data');
      for (var listener in _listeners) {
        listener(data);
      }
    });

    socket.onDisconnect((_) {
      debugPrint('Disconnected from WebSocket server');
    });
  }

  void dispose() {
    socket.dispose();
    _listeners.clear();
  }
}
