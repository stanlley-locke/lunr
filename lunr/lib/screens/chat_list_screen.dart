import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const ChatListScreen({Key? key, this.onMenuPressed}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatRoom> _rooms = [];
  List<ChatRoom> _filteredRooms = [];
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Selection Mode
  Set<String> _selectedRoomIds = {};
  bool get _isSelectionMode => _selectedRoomIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterRooms();
    });
  }

  void _filterRooms() {
    if (_searchQuery.isEmpty) {
      _filteredRooms = List.from(_rooms);
    } else {
      _filteredRooms = _rooms.where((room) {
        return room.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (room.lastMessage?.content ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> _loadContacts() async {
    final token = await _authService.getToken();
    if (token != null) {
      final rooms = await _apiService.getChatRooms(token);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _filteredRooms = List.from(rooms);
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String roomId) {
    setState(() {
      if (_selectedRoomIds.contains(roomId)) {
        _selectedRoomIds.remove(roomId);
      } else {
        _selectedRoomIds.add(roomId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedRoomIds.clear();
    });
  }

  Future<void> _deleteSelectedRooms() async {
    final token = await _authService.getToken();
    if (token == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chats?'),
        content: Text('Are you sure you want to delete ${_selectedRoomIds.length} selected chats?'),
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

    for (var roomId in _selectedRoomIds) {
      await _apiService.deleteChatRoom(token, roomId);
    }

    _clearSelection();
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _isSelectionMode
        ? CustomAppBar(
            title: '${_selectedRoomIds.length} Selected',
            leading: IconButton(
              icon: Icon(Icons.close, color: theme.iconTheme.color),
              onPressed: _clearSelection,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteSelectedRooms,
              ),
            ],
          )
        : CustomAppBar(
            title: 'Chats',
            leading: Builder(
              builder: (context) => IconButton(
                icon: Image.asset(
                  'assets/icons/lunr_humburger_icon.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: widget.onMenuPressed,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: theme.iconTheme.color),
                onPressed: () {
                  // Expand search bar
                },
              ),
            ],
          ),
      body: Column(
        children: [
          // Search Bar
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          
          // Chat List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRooms.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredRooms.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final room = _filteredRooms[index];
                          final isSelected = _selectedRoomIds.contains(room.id);
                          return _buildChatTile(room, theme, isSelected);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode ? FloatingActionButton(
        backgroundColor: theme.primaryColor,
        child: Image.asset(
          'assets/icons/lunr_plus_icon.png',
          width: 24,
          height: 24,
          color: Colors.white,
        ),
        onPressed: _showNewChatDialog,
      ) : null,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/icons/lunr_chats_icon.png',
              width: 64,
              height: 64,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No chats yet',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatRoom room, ThemeData theme, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: theme.primaryColor, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () {
            _toggleSelection(room.id);
          },
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(room.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    roomId: room.id,
                    roomName: room.displayName,
                  ),
                ),
              ).then((_) => _loadContacts());
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Text(
                        room.displayName.isNotEmpty ? room.displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: theme.primaryColor,
                          child: Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              room.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            room.lastMessage != null 
                              ? DateFormat('h:mm a').format(room.lastMessage!.timestamp.toLocal())
                              : '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.lastMessage?.content ?? 'No messages yet',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => _NewChatDialog(),
    );
  }
}

class _NewChatDialog extends StatefulWidget {
  @override
  _NewChatDialogState createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<_NewChatDialog> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers() async {
    if (_searchQuery.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    final token = await _authService.getToken();
    if (token != null) {
      final results = await _apiService.searchUsers(token, _searchQuery);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    }
  }

  void _createChat(User user) async {
    final token = await _authService.getToken();
    if (token != null) {
      final roomData = {
        'room_type': 'direct',
        'other_user_id': user.id,
      };
      
      var room = await _apiService.createChatRoom(token, roomData);
      
      if (room != null && mounted) {
        Navigator.pop(context);
        // Refresh the chat list
        final chatListState = context.findAncestorStateOfType<_ChatListScreenState>();
        chatListState?._loadContacts();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: room!.id,
              roomName: room!.displayName,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chat room'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('New Chat', style: theme.textTheme.titleLarge),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.length > 2) {
                  _searchUsers();
                }
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isSearching
                  ? Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Start typing to search users'
                                : 'No users found',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.primaryColor,
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user.username),
                              subtitle: user.bio.isNotEmpty ? Text(user.bio) : null,
                              onTap: () => _createChat(user),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}