import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String id;
  final String content;
  final String sender;
  final String receiver;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.receiver,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      sender: json['sender'] ?? '',
      receiver: json['receiver'] ?? '',
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  IO.Socket? _socket;
  String? _currentUserId;
  String? _currentChatPartnerId;

  List<ChatMessage> get messages => _messages;

  void initChat(String userId, String chatPartnerId) {
    _currentUserId = userId;
    _currentChatPartnerId = chatPartnerId;
    _connectSocket();
    _fetchPreviousMessages();
  }

  String get _baseUrl {
    final devHostname = dotenv.env['DEV_HOSTNAME'];
    return devHostname ??
        '10.0.2.2'; // Fallback to 10.0.2.2 if DEV_HOSTNAME is not set
  }

  void _connectSocket() {
    final socketUrl = 'http://${_baseUrl}:3000';
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();
    _socket!.on('connect', (_) => print('Connected to socket server'));
    _socket!.on('newMessage', (data) {
      final newMessage = ChatMessage.fromJson(data);
      _addMessage(newMessage);
    });

    _socket!.on('error', (error) => print('Socket error: $error'));
    _socket!.on('disconnect', (_) => print('Disconnected from socket server'));

    _socket!.emit('joinRoom', '$_currentUserId-$_currentChatPartnerId');
  }

  Future<void> _fetchPreviousMessages() async {
    final apiUrl = 'http://${_baseUrl}:3000/api';
    final url = '$apiUrl/chat/messages/$_currentUserId/$_currentChatPartnerId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _messages = data.map((item) => ChatMessage.fromJson(item)).toList();
        notifyListeners();
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  void sendMessage(String content) {
    if (_currentUserId == null || _currentChatPartnerId == null) return;

    final message = {
      'content': content,
      'sender': _currentUserId,
      'receiver': _currentChatPartnerId,
    };
    _socket?.emit('sendMessage', message);
  }

  void _addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}