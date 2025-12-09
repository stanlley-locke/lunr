import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/chat_room.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';

class ArchivedChatsScreen extends StatefulWidget {
  @override
  _ArchivedChatsScreenState createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  List<ChatRoom> _archivedRooms = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _loadArchivedChats();
  }

  Future<void> _fetchCurrentUserId() async {
    final uid = await _authService.getUserId();
    if (mounted) setState(() => _currentUserId = uid);
  }

  Future<void> _loadArchivedChats() async {
    final token = await _authService.getToken();
    if (token != null) {
      try {
        // Fetch all rooms, then filter locally for "archived"
        // Ideally backend should provide a filter parameter, but for now we fetch all and filter
        final rooms = await _apiService.getChatRooms(token);
        final uid = await _authService.getUserId();
        
        if (mounted && uid != null) {
          setState(() {
            _archivedRooms = rooms.where((room) => room.isArchivedFor(uid)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching archived chats: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unarchiveChat(ChatRoom room) async {
    final token = await _authService.getToken();
    if (token != null) {
      final success = await _apiService.unarchiveChat(token, room.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat unarchived')));
        _loadArchivedChats(); // Refresh
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unarchive chat')));
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
                  Text('No archived chats', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: _archivedRooms.length,
              separatorBuilder: (ctx, i) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final room = _archivedRooms[index];
                final displayName = _currentUserId != null ? room.getDisplayName(_currentUserId!) : room.name;
                
                return _buildArchivedTile(room, displayName, theme);
              },
            ),
    );
  }

  Widget _buildArchivedTile(ChatRoom room, String title, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        title: Text(
          title, 
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)
        ),
        subtitle: Text(
          room.lastMessage?.content ?? 'No messages',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.unarchive, color: theme.primaryColor),
          onPressed: () => _unarchiveChat(room),
          tooltip: 'Unarchive',
        ),
        onTap: () {
           Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: room.id,
                  roomName: title,
                ),
              ),
            ).then((_) => _loadArchivedChats());
        },
      ),
    );
  }
}
