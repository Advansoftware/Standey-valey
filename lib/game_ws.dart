import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Gerenciador de conexão WebSocket para eventos em tempo real da Stardew Web API.
class GameWebSocket {
  final void Function(Map<String, dynamic> event) onEvent;
  final void Function()? onConnected;
  final void Function()? onDisconnected;

  WebSocket? _socket;
  Timer? _reconnectTimer;
  String _currentUrl = '';
  bool _active = false;
  bool _connecting = false;

  GameWebSocket({
    required this.onEvent,
    this.onConnected,
    this.onDisconnected,
  });

  bool get isConnected => _socket?.readyState == WebSocket.open;

  void connect(String httpBaseUrl) {
    var wsUrl = httpBaseUrl.trim();
    if (wsUrl.isEmpty) return;

    if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    } else if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    } else {
      wsUrl = 'ws://$wsUrl';
    }

    if (!wsUrl.endsWith('/')) {
      wsUrl = '$wsUrl/';
    }

    _currentUrl = wsUrl;
    _active = true;
    _startConnect();
  }

  void disconnect() {
    _active = false;
    _connecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      _socket?.close(WebSocketStatus.normalClosure, 'Client closed');
    } catch (_) {}
    _socket = null;
  }

  Future<void> _startConnect() async {
    if (!_active || _connecting || _currentUrl.isEmpty) return;
    _connecting = true;

    try {
      final uri = Uri.parse(_currentUrl);
      final socket = await WebSocket.connect(uri.toString())
          .timeout(const Duration(seconds: 4));

      if (!_active) {
        socket.close();
        return;
      }

      _socket = socket;
      _connecting = false;
      onConnected?.call();

      socket.listen(
        (data) {
          try {
            if (data is String) {
              final json = jsonDecode(data);
              if (json is Map<String, dynamic>) {
                onEvent(json);
              } else if (json is Map) {
                onEvent(json.cast<String, dynamic>());
              }
            }
          } catch (_) {}
        },
        onError: (err) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _connecting = false;
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _socket = null;
    _connecting = false;
    onDisconnected?.call();
    if (_active) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (_active && _socket == null) {
          _startConnect();
        }
      });
    }
  }
}
