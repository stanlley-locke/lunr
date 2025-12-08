import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class BlockedContactsScreen extends StatefulWidget {
  @override
  _BlockedContactsScreenState createState() => _BlockedContactsScreenState();
}

class _BlockedContactsScreenState extends State<BlockedContactsScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  List<User> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final token = await _authService.getToken();
    if (token != null) {
      final users = await _apiService.getBlockedUsers(token);
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(User user) async {
    final token = await _authService.getToken();
    if (token != null) {
      final success = await _apiService.unblockUser(token, user.id);
      if (success) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.id == user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.username} unblocked')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Blocked Contacts',
          style: GoogleFonts.outfit(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator()) 
          : _blockedUsers.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return _buildBlockedUserTile(theme, user);
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: theme.disabledColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No blocked contacts',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserTile(ThemeData theme, User user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
              ? CachedNetworkImageProvider(user.avatar!)
              : null,
          child: user.avatar == null || user.avatar!.isEmpty
              ? Text(
                  user.username[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.username,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        trailing: TextButton(
          onPressed: () => _unblockUser(user),
          child: Text(
            'Unblock',
            style: GoogleFonts.inter(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
