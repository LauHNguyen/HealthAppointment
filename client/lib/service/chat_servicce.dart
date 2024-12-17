import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';

class ChatService {
  late WebSocketChannel _channel;
  Function(Message)? onMessageReceived;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel.stream.listen((message) {
      final decodedMessage = Message.fromJson(jsonDecode(message));
      if (onMessageReceived != null) {
        onMessageReceived!(decodedMessage);
      }
    });
  }

  void sendMessage(Message message) {
    _channel.sink.add(jsonEncode(message.toJson()));
  }

  void dispose() {
    _channel.sink.close();
  }
}
