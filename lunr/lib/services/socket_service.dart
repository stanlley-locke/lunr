import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket _socket;
  final AuthService _authService = AuthService();
  bool _isConnected = false;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket get socket => _socket;
  bool get isConnected => _isConnected;

  Future<void> initSocket() async {
    final token = await _authService.getToken();
    if (token == null) return;

    // Base URL without /api
    const String socketUrl = 'https://humble-sniffle-wr46p9pq554crp5-8000.app.github.dev';

    _socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setExtraHeaders({'Authorization': 'Bearer $token'}) // Common pattern
      .setQuery({'token': token}) // Also common
      .build()
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to socket server');
      _isConnected = true;
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket server');
      _isConnected = false;
    });

    _socket.onError((data) => print('Socket Error: $data'));
    _socket.onConnectError((data) => print('Connect Error: $data'));
  }

  void disconnect() {
    _socket.disconnect();
  }

  void joinRoom(String roomId) {
    if (!_isConnected) return;
    print('Joining room: $roomId');
    _socket.emit('join', {'room_id': roomId});
  }

  void leaveRoom(String roomId) {
    if (!_isConnected) return;
    print('Leaving room: $roomId');
    _socket.emit('leave', {'room_id': roomId});
  }

  void onMessage(Function(dynamic) callback) {
    _socket.on('message', callback);
  }
  
  void offMessage() {
    _socket.off('message');
  }
}
