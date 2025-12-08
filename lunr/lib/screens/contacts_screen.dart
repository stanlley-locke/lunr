import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_app_bar.dart';
import '../models/user.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
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
      _filterContacts();
    });
  }

  void _filterContacts() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = List.from(_contacts);
    } else {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.alias.isNotEmpty ? contact.alias : contact.user.username;
        return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               contact.user.username.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> _loadContacts({bool forceRefresh = false}) async {
    // If not forcing refresh, always load local first for speed
    if (!forceRefresh) {
      final localContacts = await _databaseService.getContacts();
      if (mounted) {
        setState(() {
          _contacts = localContacts;
          _filterContacts();
          if (_contacts.isNotEmpty) _isLoading = false;
        });
      }
    }

    // Sync remote
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final remoteContacts = await _apiService.getContacts(token);
        
        // Update local DB
        await _databaseService.insertContacts(remoteContacts);
        
        if (mounted) {
          setState(() {
            _contacts = remoteContacts;
            _filterContacts();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading contacts: $e');
      // If we failed to load remote, just ensure we aren't stuck in loading state
      if (mounted) {
         setState(() {
           _isLoading = false;
         });
      }
    }
  }
  
  Future<void> _handleRefresh() async {
    await _loadContacts(forceRefresh: true);
  }

  Future<void> _startChat(Contact contact) async {
    final token = await _authService.getToken();
    if (token != null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(child: CircularProgressIndicator()),
      );

      final roomData = {
        'room_type': 'direct',
        'other_user_id': contact.user.id,
      };
      
      final room = await _apiService.createChatRoom(token, roomData);
      
      // Hide loading
      Navigator.pop(context); 

      if (room != null) {
        final chatName = contact.alias.isNotEmpty ? contact.alias : contact.user.username;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: room.id,
              roomName: chatName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat')),
        );
      }
    }
  }

  void _showAddContactDialog() {
    final TextEditingController _usernameController = TextEditingController();
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter username to add',
                ),
              ),
              if (_isAdding) Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isAdding ? null : () async {
                final username = _usernameController.text.trim();
                if (username.isEmpty) return;

                setState(() => _isAdding = true);
                final token = await _authService.getToken();
                if (token != null) {
                  final contact = await _apiService.addContact(token, username);
                  if (contact != null) {
                    await _databaseService.insertContact(contact);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadContacts(); 
                    }
                  } else {
                    setState(() => _isAdding = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add contact or user not found')),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(Contact contact) {
    final TextEditingController _aliasController = TextEditingController(text: contact.alias);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Contact'),
        content: TextField(
          controller: _aliasController,
          decoration: InputDecoration(labelText: 'Alias (Display Name)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               final alias = _aliasController.text.trim();
               final token = await _authService.getToken();
               if (token != null) {
                 final updated = await _apiService.updateContact(token, contact.id, alias);
                 if (updated != null) {
                   await _databaseService.insertContact(updated);
                   _loadContacts();
                   Navigator.pop(context);
                 }
               }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Contact?'),
        content: Text('Remove ${contact.alias.isNotEmpty ? contact.alias : contact.user.username} from contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final token = await _authService.getToken();
      if (token != null) {
        final success = await _apiService.deleteContact(token, contact.id);
        if (success) {
          await _databaseService.deleteContact(contact.id);
          _loadContacts();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Contacts',
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddContactDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
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
          
          // Contact List
          Expanded(
            child: _isLoading && _contacts.isEmpty
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: theme.primaryColor,
                  child: _filteredContacts.isEmpty
                      ? ListView(
                          physics: AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 100),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icons/lunr_contacts_icon.png',
                                    width: 64,
                                    height: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(_searchQuery.isEmpty ? 'No contacts yet' : 'No contacts found', 
                                    style: theme.textTheme.titleMedium
                                  ),
                                  if (_searchQuery.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Add people to start chatting!',
                                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredContacts.length,
                          separatorBuilder: (ctx, index) => SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            return _buildContactTile(contact, theme);
                          },
                        ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Contact contact, ThemeData theme) {
    final displayName = contact.alias.isNotEmpty ? contact.alias : contact.user.username;
    
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _startChat(contact),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (contact.alias.isNotEmpty)
                        Text(
                          contact.user.username,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.disabledColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Image.asset('assets/icons/lunr_chats_icon.png', width: 24, height: 24),
                      onPressed: () => _startChat(contact),
                      tooltip: 'Message',
                    ),
                    IconButton(
                      icon: Image.asset('assets/icons/lunr_phone_icon.png', width: 24, height: 24),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Audio calls coming soon!')),
                         );
                      },
                      tooltip: 'Call',
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: theme.disabledColor),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit Alias')]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete')]),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') _showEditContactDialog(contact);
                        if (value == 'delete') _deleteContact(contact);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
