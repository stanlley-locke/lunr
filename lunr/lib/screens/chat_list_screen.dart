import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/chat_room.dart';
import 'login_screen.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
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
      setState(() {
        _rooms = rooms;
        _filteredRooms = List.from(rooms);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.backgroundColor,
        elevation: 8,
        shadowColor: themeProvider.isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            Image.asset(
              'assets/icons/lunr_chats_icon.png',
              width: 24,
              height: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Chats',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/lunr_humburger_icon.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              _showMenuBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeProvider.searchBarColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: themeProvider.subtitleColor),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: themeProvider.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(
                        color: themeProvider.subtitleColor,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                    },
                    child: Icon(Icons.clear, color: themeProvider.subtitleColor),
                  ),
              ],
            ),
          ),
          
          // Chat List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredRooms.isEmpty
                    ? _searchQuery.isNotEmpty
                        ? _buildNoSearchResults()
                        : _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredRooms.length,
                        itemBuilder: (context, index) {
                          final room = _filteredRooms[index];
                          return _buildChatTile(room);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF2196F3),
        child: Image.asset(
          'assets/icons/lunr_plus_icon.png',
          width: 24,
          height: 24,
          color: Colors.white,
        ),
        onPressed: () {
          _showNewChatDialog();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/lunr_chats_icon.png',
              width: 80,
              height: 80,
              color: themeProvider.subtitleColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: TextStyle(
              color: themeProvider.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatRoom room) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            child: Text(
              room.displayName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        title: Text(
          room.displayName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.textColor,
          ),
        ),
        subtitle: Text(
          room.lastMessage?.content ?? 'No messages yet',
          style: TextStyle(
            color: themeProvider.subtitleColor,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '12:30 PM',
              style: TextStyle(
                color: themeProvider.subtitleColor,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                roomId: room.id,
                roomName: room.displayName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoSearchResults() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: themeProvider.subtitleColor,
          ),
          SizedBox(height: 16),
          Text(
            'No chats found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              color: themeProvider.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => _NewChatDialog(),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Image.asset('assets/icons/lunr_profile_icon.png', width: 24),
                title: Text('Profile'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Image.asset('assets/icons/lunr_settings_icon.png', width: 24),
                title: Text('Settings'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _authService.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
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
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _createChat(User user) async {
    final token = await _authService.getToken();
    if (token != null) {
      // Try different data formats that the backend might expect
      final roomData = {
        'name': user.username,
        'room_type': 'direct',
        'participant_ids': [user.id],
      };
      
      var room = await _apiService.createChatRoom(token, roomData);
      
      // If first format fails, try alternative format
      if (room == null) {
        final altRoomData = {
          'display_name': user.username,
          'room_type': 'direct',
          'participants': [user.id],
        };
        room = await _apiService.createChatRoom(token, altRoomData);
      }
      
      // Try third format
      if (room == null) {
        final altRoomData2 = {
          'name': user.username,
          'type': 'direct',
          'members': [user.id],
        };
        room = await _apiService.createChatRoom(token, altRoomData2);
      }
      
      if (room != null) {
        Navigator.pop(context);
        // Refresh the chat list
        if (context.mounted) {
          final chatListState = context.findAncestorStateOfType<_ChatListScreenState>();
          chatListState?._loadContacts();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: room!.id,
              roomName: room!.displayName,
            ),
          ),
        );
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create chat room'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return AlertDialog(
      backgroundColor: themeProvider.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'New Chat',
        style: TextStyle(color: themeProvider.textColor),
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: TextStyle(color: themeProvider.textColor),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(color: themeProvider.subtitleColor),
                prefixIcon: Icon(Icons.search, color: themeProvider.subtitleColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: themeProvider.subtitleColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF2196F3)),
                ),
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
                            style: TextStyle(color: themeProvider.subtitleColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(0xFF2196F3),
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.username,
                                style: TextStyle(color: themeProvider.textColor),
                              ),
                              subtitle: user.bio.isNotEmpty
                                  ? Text(
                                      user.bio,
                                      style: TextStyle(color: themeProvider.subtitleColor),
                                    )
                                  : user.statusMessage.isNotEmpty
                                      ? Text(
                                          user.statusMessage,
                                          style: TextStyle(color: themeProvider.subtitleColor),
                                        )
                                      : null,
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
          child: Text(
            'Cancel',
            style: TextStyle(color: themeProvider.subtitleColor),
          ),
        ),
      ],
    );
  }
}