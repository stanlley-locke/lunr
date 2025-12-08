import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/contact.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_app_bar.dart';
import '../models/user.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    // Load local first
    final localContacts = await _databaseService.getContacts();
    if (mounted) {
      setState(() {
        _contacts = localContacts;
        _isLoading = false;
      });
    }

    // Sync remote
    final token = await _authService.getToken();
    if (token != null) {
      final remoteContacts = await _apiService.getContacts(token);
      await _databaseService.insertContacts(remoteContacts);
      if (mounted) {
        setState(() {
          _contacts = remoteContacts;
          _isLoading = false;
        });
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
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined, size: 64, color: theme.disabledColor),
                      SizedBox(height: 16),
                      Text('No contacts yet', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final displayName = contact.alias.isNotEmpty ? contact.alias : contact.user.username;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(displayName, style: theme.textTheme.bodyLarge),
                      subtitle: contact.alias.isNotEmpty ? Text(contact.user.username) : null,
                      trailing: PopupMenuButton(
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
                    );
                  },
                ),
    );
  }
}
