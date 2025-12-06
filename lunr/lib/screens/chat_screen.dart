// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final int contactId;
  final String contactName;

  const ChatScreen({
    Key? key,
    required this.contactId,
    required this.contactName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;
  late int _currentUserId;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _authService.getUserId().then((id) {
      if (id != null) {
        _currentUserId = id;
        _loadMessages();
      }
    });
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final token = await _authService.getToken();
    if (token != null) {
      final messages = await _apiService.getMessages(token, widget.contactId);
      final parsedMessages = messages
          .map((msg) => Message.fromJson(msg))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (mounted) {
        setState(() {
          _messages = parsedMessages;
          _isLoading = false;
        });
        
        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _loadMessages();
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    if (mounted) setState(() => _isSending = true);
    final token = await _authService.getToken();
    
    if (token != null) {
      final success = await _apiService.sendMessage(
        token,
        widget.contactId,
        messageText,
      );
      
      if (success && mounted) {
        _messageController.clear();
        _loadMessages(); // Refresh immediately
      }
    }
    
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages.reversed.toList()[index];
                          final isOwn = message.senderId == _currentUserId;
                          return Container(
                            padding: EdgeInsets.all(8),
                            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isOwn ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message.content,
                                style: TextStyle(
                                  color: isOwn ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: _isSending 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}