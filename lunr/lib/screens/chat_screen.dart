import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
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
  late int _currentUserId;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  // Selection Mode
  Set<String> _selectedMessageIds = {};
  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      _currentUserId = userId;
      await _loadMessages();
      
      // Initialize socket
      await _socketService.initSocket();
      _socketService.joinRoom(widget.roomId);
      
      _socketService.onMessage((data) {
        print('New message received: $data');
        if (mounted) {
          setState(() {
            // Avoid duplicates if any
            final newMessage = Message.fromJson(data);
            if (!_messages.any((m) => m.id == newMessage.id)) {
              _messages.add(newMessage);
              // Sort again just in case
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            }
          });
          _scrollToBottom();
        }
      });
    }
  }

  @override
  void dispose() {
    _socketService.leaveRoom(widget.roomId);
    _socketService.offMessage();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final token = await _authService.getToken();
    if (token != null) {
      final messages = await _apiService.getRoomMessages(token, widget.roomId);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    if (mounted) setState(() => _isSending = true);
    final token = await _authService.getToken();
    
    if (token != null) {
      // Send via API
      final message = await _apiService.sendMessage(
        token,
        widget.roomId,
        messageText,
      );
      
      if (message != null && mounted) {
        _messageController.clear();
        // We rely on the socket to receive the message back and add it to the list
      }
    }
    
    if (mounted) setState(() => _isSending = false);
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  Future<void> _deleteSelectedMessages() async {
    final token = await _authService.getToken();
    if (token == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Messages?'),
        content: Text('Are you sure you want to delete ${_selectedMessageIds.length} selected messages?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    for (var messageId in _selectedMessageIds) {
      await _apiService.deleteMessage(token, messageId);
    }

    _clearSelection();
    _loadMessages(); // Reload to reflect deletions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
        ? AppBar(
            title: Text('${_selectedMessageIds.length} Selected'),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: _clearSelection,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelectedMessages,
              ),
            ],
          )
        : AppBar(title: Text(widget.roomName)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isOwn = message.sender.id == _currentUserId;
                          final isSelected = _selectedMessageIds.contains(message.id);
                          
                          return GestureDetector(
                            onLongPress: () {
                              if (isOwn) _toggleSelection(message.id);
                            },
                            onTap: () {
                              if (_isSelectionMode && isOwn) {
                                _toggleSelection(message.id);
                              }
                            },
                            child: Container(
                              color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
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
                            ),
                          );
                        },
                      ),
          ),
          if (!_isSelectionMode)
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