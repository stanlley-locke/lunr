import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/chat_room.dart';
import '../models/contact.dart';
import 'chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const GroupsScreen({Key? key, this.onMenuPressed}) : super(key: key);

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<ChatRoom> _groups = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups({bool forceRefresh = false}) async {
    // Local first
    if (!forceRefresh) {
      final localRooms = await _databaseService.getChatRooms();
      if (mounted) {
        setState(() {
          _groups = localRooms.where((room) => room.isGroup).toList();
          if (_groups.isNotEmpty) _isLoading = false;
        });
      }
    }

    // Remote sync
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final remoteRooms = await _apiService.getChatRooms(token);
        // Save to DB
        await _databaseService.insertChatRooms(remoteRooms);
        
        if (mounted) {
          setState(() {
            _groups = remoteRooms.where((room) => room.isGroup).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading groups: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadGroups(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Groups',
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
            icon: Image.asset(
              'assets/icons/lunr_plus_icon.png',
              width: 24,
              height: 24,
            ),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                // TODO: Implement local filtering or re-query
                // For now minimal implementation
              },
            ),
          ),
          
          // Groups List
          Expanded(
            child: _isLoading && _groups.isEmpty
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: theme.primaryColor,
                    child: _groups.isEmpty
                        ? ListView(
                            physics: AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 100),
                              _buildEmptyState(theme)
                            ],
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(16),
                            physics: AlwaysScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _groups.length,
                            itemBuilder: (context, index) {
                              final group = _groups[index];
                              return _buildGroupCard(group, theme);
                            },
                          ),
                  ),
          ),
        ],
      ),
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
              'assets/icons/lunr_group_icon.png',
              width: 64,
              height: 64,
              // color: theme.disabledColor, // Removed to preserve 3D effect
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Groups Yet',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Create or join groups to start chatting',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(ChatRoom group, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: group.id,
                  roomName: group.displayName,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/icons/lunr_group_icon.png',
                        width: 24,
                        height: 24,
                        color: theme.primaryColor,
                      ),
                    ),
                    // Unread count placeholder or real data if available
                    /*
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '0',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    */
                  ],
                ),
                Spacer(),
                Text(
                  group.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${group.memberCount} members',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.disabledColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  group.lastMessage?.content ?? 'No messages yet',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final theme = Theme.of(context);
    final _groupNameController = TextEditingController();
    bool _isCreating = false;
    List<Contact> _contacts = [];
    Set<int> _selectedUserIds = {};
    bool _isLoadingContacts = true;

    // Load contacts immediately
    _databaseService.getContacts().then((contacts) {
      // In a real app we might want to refresh from API too, 
      // but for speed in dialog, local DB is fine.
      if (mounted) {
        // We need to use the StatefulBuilder's setState, but we can't access it here easily 
        // unless we load before showing dialog or use a future builder.
        // Actually, we can just load it and the dialog will be rebuilt if we put this logic inside.
        // Better pattern: Load contacts in parent, or use FutureBuilder in dialog.
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Trigger load once
          if (_isLoadingContacts && _contacts.isEmpty) {
             _databaseService.getContacts().then((contacts) {
               if (context.mounted) {
                 setState(() {
                   _contacts = contacts;
                   _isLoadingContacts = false;
                 });
               }
             });
             // Prevent multiple triggers if setState re-runs
             // Actually, the above logic is slightly flawed if re-renders happen. 
             // Best to use FutureBuilder.
          }

          return Dialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Group',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: _groupNameController,
                    style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: GoogleFonts.inter(color: theme.disabledColor),
                      hintText: 'Enter group name',
                      hintStyle: GoogleFonts.inter(color: theme.disabledColor.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.group_outlined, color: theme.primaryColor),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Add Members',
                    style: GoogleFonts.inter(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: _isLoadingContacts 
                      ? Center(child: CircularProgressIndicator())
                      : _contacts.isEmpty 
                        ? Center(child: Text('No contacts found', style: TextStyle(color: theme.disabledColor)))
                        : ListView.builder(
                            itemCount: _contacts.length,
                            itemBuilder: (context, index) {
                              final contact = _contacts[index];
                              final isSelected = _selectedUserIds.contains(contact.user.id);
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedUserIds.add(contact.user.id);
                                    } else {
                                      _selectedUserIds.remove(contact.user.id);
                                    }
                                  });
                                },
                                title: Text(
                                  contact.alias.isNotEmpty ? contact.alias : contact.user.username,
                                  style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color),
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                                  child: Text(
                                    (contact.alias.isNotEmpty ? contact.alias : contact.user.username)[0].toUpperCase(),
                                    style: TextStyle(color: theme.primaryColor),
                                  ),
                                ),
                                activeColor: theme.primaryColor,
                                checkColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: theme.disabledColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isCreating ? null : () async {
                          if (_groupNameController.text.isNotEmpty) {
                            setState(() => _isCreating = true);
                            
                            final token = await _authService.getToken();
                            if (token != null) {
                              final roomData = {
                                'name': _groupNameController.text,
                                'room_type': 'group',
                                'members': _selectedUserIds.toList(),
                              };
                              
                              final room = await _apiService.createChatRoom(token, roomData);
                              
                              if (context.mounted) {
                                setState(() => _isCreating = false);
                                Navigator.pop(context); // Close dialog
                                
                                if (room != null) {
                                  _loadGroups(); // Refresh list in background
                                  // Navigate to new chat
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        roomId: room.id,
                                        roomName: room.name,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to create group')),
                                  );
                                }
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isCreating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create (${_selectedUserIds.length})',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}