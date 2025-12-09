import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/chat_room.dart';
import 'chat_screen.dart';

class ArchivedChatsScreen extends StatefulWidget {
  @override
  _ArchivedChatsScreenState createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  List<ChatRoom> _archivedRooms = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadArchivedChats();
  }

  Future<void> _loadArchivedChats() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    
    if (token != null && userId != null) {
      if (mounted) setState(() => _currentUserId = userId);
      try {
        // Ideally backend has 'getArchivedChats', but for now we filter locally if backend implies it
        // Or we use existing getChatRooms and filter by isArchived property on membership
        final rooms = await _apiService.getChatRooms(token);
        if (mounted) {
          setState(() {
            _archivedRooms = rooms.where((r) => r.isArchivedFor(userId)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unarchiveChat(String roomId) async {
    final token = await _authService.getToken();
    if (token != null) {
      // Create unarchive method in ApiService if exists, or use generic update
      // Assuming 'unarchive' endpoint exists as per previous plan
      // Or simply toggle logic
      // For now, let's assume we call specific endpoint
       final success = await _apiService.unarchiveChat(token, roomId);
       if (success) {
         _loadArchivedChats();
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat unarchived')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Archived Chats', style: theme.textTheme.titleLarge),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator()) 
        : _archivedRooms.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.archive_outlined, size: 64, color: theme.disabledColor),
                    SizedBox(height: 16),
                    Text('No archived chats', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
                  ],
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: _archivedRooms.length,
                separatorBuilder: (ctx, i) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final room = _archivedRooms[index];
                  return _buildArchivedTile(room, theme);
                },
              ),
    );
  }

  Widget _buildArchivedTile(ChatRoom room, ThemeData theme) {
    String title = _currentUserId != null ? room.getDisplayName(_currentUserId!) : room.name;
    if (title.isEmpty) title = 'Chat';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Text(
            title[0].toUpperCase(),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          room.lastMessage?.content ?? 'No messages',
          maxLines: 1, 
          overflow: TextOverflow.ellipsis
        ),
        trailing: IconButton(
          icon: Icon(Icons.unarchive, color: theme.primaryColor),
          onPressed: () => _unarchiveChat(room.id),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(roomId: room.id, roomName: title),
            ),
          ).then((_) => _loadArchivedChats());
        },
      ),
    );
  }
}
