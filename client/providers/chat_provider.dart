import 'package:flutter/material.dart';

class ChatMessage {
  final String content;
  final String sender;
  final DateTime timestamp;

  ChatMessage(
      {required this.content, required this.sender, required this.timestamp});
}

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => _messages;

  void sendMessage(String content, String senderId) {
    final newMessage = ChatMessage(
      content: content,
      sender: senderId,
      timestamp: DateTime.now(),
    );
    _messages.add(newMessage);
    notifyListeners();
  }

  void initChat(String url) {
    // Initialize chat connection here
    print('Initializing chat with URL: $url');
  }
}
