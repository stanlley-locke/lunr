import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../models/contact.dart';
import '../services/database_service.dart';
import '../models/user_settings.dart';

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
  final DatabaseService _databaseService = DatabaseService();

  ChatRoom? _chatRoom;
  List<Contact> _contacts = []; // For add member dialog
  
  // Selection Mode
  Set<String> _selectedMessageIds = {};
  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  // Handler reference for removal
  late Function(dynamic) _messageHandler;
  
  UserSettings? _userSettings;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final token = await _authService.getToken();
    if (token != null) {
      final settings = await _apiService.getSettings(token);
      if (mounted && settings != null) {
        setState(() => _userSettings = settings);
      }
    }
  }

  void _initializeChat() async {
    final userId = await _authService.getUserId();
    if (userId != null) {
      _currentUserId = userId;
      
      // Fetch Room Details
      final room = await _apiService.getChatRoom(await _authService.getToken() ?? '', widget.roomId);
      if (mounted) setState(() => _chatRoom = room);

      // Mark as read immediately
      _apiService.markChatRead(await _authService.getToken() ?? '', widget.roomId);
      _databaseService.markRoomAsRead(widget.roomId);

      await _loadMessages(forceRefresh: false); // Load local first
      
      // Initialize socket
      await _socketService.initSocket();
      _socketService.joinRoom(widget.roomId);
      _socketService.activeRoomId = widget.roomId; // Track active room
      
      // Define handler
      _messageHandler = (data) async {
        print('New message received: $data');
        if (mounted) {
          final newMessage = Message.fromJson(data);
          
          // Save to local DB (no unread increment)
          await _databaseService.insertMessage(newMessage);
          
          setState(() {
            // Avoid duplicates if any
            if (!_messages.any((m) => m.id == newMessage.id)) {
              _messages.add(newMessage);
              // Sort again just in case
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            }
          });
          _scrollToBottom();
        }
      };

      _socketService.onMessage(_messageHandler);
      
      // Sync in background after local load
      await _loadMessages(forceRefresh: true);
      // Mark read again after sync to be sure
      _apiService.markChatRead(await _authService.getToken() ?? '', widget.roomId);
    }
  }

  // Group Management Methods
  void _showGroupMenu() {
    if (_chatRoom == null || !_chatRoom!.isGroup) return;
    
    final bool isAdmin = _chatRoom!.members.any((m) => m.user.id == _currentUserId && m.role == 'admin');

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Group Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('View Members (${_chatRoom!.memberCount})'),
              onTap: () {
                Navigator.pop(context);
                _showMembersDialog(isAdmin);
              },
            ),
            if (isAdmin)
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Add Members'),
                onTap: () {
                   Navigator.pop(context);
                   _showAddMembersDialog();
                },
              ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Exit Group', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmExitGroup();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersDialog(bool isAdmin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Members'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _chatRoom?.members.length ?? 0,
            itemBuilder: (context, index) {
              final member = _chatRoom!.members[index];
              return ListTile(
                title: Text(member.user.username),
                subtitle: Text(member.role),
                trailing: (isAdmin && member.user.id != _currentUserId) 
                  ? PopupMenuButton(
                      itemBuilder: (context) => [
                        if (member.role != 'admin')
                          PopupMenuItem(
                            value: 'promote',
                            child: Text('Promote to Admin'),
                          ),
                        if (member.role == 'admin')
                          PopupMenuItem(
                            value: 'demote',
                            child: Text('Demote to Member'),
                          ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove from Group', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                      onSelected: (value) => _handleMemberAction(member.user.id, value.toString()),
                    )
                  : null,
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
      ),
    );
  }

  Future<void> _handleMemberAction(int userId, String action) async {
    final token = await _authService.getToken();
    if (token == null) return;

    bool success = false;
    if (action == 'remove') {
      success = await _apiService.removeMember(token, widget.roomId, userId);
    } else if (action == 'promote') {
      success = await _apiService.updateMemberRole(token, widget.roomId, userId, 'admin');
    } else if (action == 'demote') {
      success = await _apiService.updateMemberRole(token, widget.roomId, userId, 'member');
    }

    if (success) {
      // Refresh room details
      final updatedRoom = await _apiService.getChatRoom(token, widget.roomId);
      if (mounted) setState(() => _chatRoom = updatedRoom);
      Navigator.pop(context); // Close members list to refresh or just setState
      // Re-open list? Or just toast.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action successful')));
    }
  }

  void _showAddMembersDialog() {
     // Load contacts
     _databaseService.getContacts().then((contacts) {
       if (mounted) setState(() => _contacts = contacts);
     });
     
     Set<int> selectedIds = {};

     showDialog(
       context: context,
       builder: (context) => StatefulBuilder(
         builder: (context, setState) => AlertDialog(
           title: Text('Add Members'),
           content: Container(
             width: double.maxFinite,
             child: ListView.builder(
               shrinkWrap: true,
               itemCount: _contacts.length,
               itemBuilder: (context, index) {
                 final contact = _contacts[index];
                 // Filter already members
                 if (_chatRoom!.members.any((m) => m.user.id == contact.user.id)) return SizedBox.shrink();

                 final isSelected = selectedIds.contains(contact.user.id);
                 return CheckboxListTile(
                   value: isSelected,
                   title: Text(contact.alias.isNotEmpty ? contact.alias : contact.user.username),
                   onChanged: (val) {
                     setState(() {
                       if (val == true) selectedIds.add(contact.user.id);
                       else selectedIds.remove(contact.user.id);
                     });
                   },
                 );
               },
             ),
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
             TextButton(
               onPressed: () async {
                  final token = await _authService.getToken();
                  if (token != null && selectedIds.isNotEmpty) {
                    await _apiService.addMembers(token, widget.roomId, selectedIds.toList());
                    final updatedRoom = await _apiService.getChatRoom(token, widget.roomId);
                    if (mounted) setState(() => _chatRoom = updatedRoom);
                  }
                  Navigator.pop(context);
               },
               child: Text('Add'),
             ),
           ],
         ),
       ),
     );
  }

  Future<void> _confirmExitGroup() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Group?'),
        content: Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final token = await _authService.getToken();
      if (token != null) {
        bool success = await _apiService.removeMember(token, widget.roomId, _currentUserId);
        if (success) {
          Navigator.pop(context); // Leave chat screen
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to exit group')));
        }
      }
    }
  }

  @override
  void dispose() {
    _socketService.activeRoomId = null; // Clear active room
    _socketService.leaveRoom(widget.roomId);
    // if (this._currentUserId != null) { // ERROR: _currentUserId is not nullable int, it's late int. 
    // Need to check if initialized or use try-catch
       try {
         _socketService.offMessage(_messageHandler);
       } catch (e) {
         // Handler might not have been assigned if init failed
       }
    // }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool forceRefresh = false}) async {
    // 1. Load from DB if not forcing refresh (or load anyway to show cache)
    if (!forceRefresh) {
      final localMessages = await _databaseService.getMessages(widget.roomId);
      if (mounted && localMessages.isNotEmpty) {
        setState(() {
          _messages = localMessages;
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
        // Scroll to bottom after loading local messages
        // Use a slight delay to ensure list is built
        Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
      }
    }

    // 2. Sync from API
    if (forceRefresh || _messages.isEmpty) {
      final token = await _authService.getToken();
      if (token != null) {
        try {
          final messages = await _apiService.getRoomMessages(token, widget.roomId);
          
          // Save to DB
          await _databaseService.insertMessages(messages);
          
          if (mounted) {
            setState(() {
              _messages = messages;
              _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              _isLoading = false;
            });
            _scrollToBottom();
          }
        } catch (e) {
          print("Error fetching messages: $e");
          if (mounted && _messages.isEmpty) {
            setState(() => _isLoading = false);
          }
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadMessages(forceRefresh: true);
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
      await _databaseService.deleteMessage(messageId);
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
        : AppBar(
            title: Text(widget.roomName),
            actions: [
              if (_chatRoom?.isGroup == true)
                IconButton(
                  icon: Image.asset(
                    'assets/icons/lunr_plus_icon.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: _showGroupMenu,
                )
            ],
          ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('No messages yet'))
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          physics: AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isOwn = message.sender.id == _currentUserId;
                            final isSelected = _selectedMessageIds.contains(message.id);
                            
                            return GestureDetector(
                              onLongPress: () {
                                _toggleSelection(message.id);
                              },
                              onTap: () {
                                if (_isSelectionMode) {
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
            ),
        ],
        ),
      ),
    );
  }
}
