import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _isLoading = true;
  User? _currentUser;

  // Settings
  bool _showLastSeen = true;
  bool _showProfilePhoto = true;
  bool _showReadReceipts = true;
  bool _showStatus = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 1. Load from Cache (Database)
    final cachedUser = await _databaseService.getCurrentUser();
    if (cachedUser != null) {
      if (mounted) {
        setState(() {
          _currentUser = cachedUser;
          _updateLocalStateFromUser(cachedUser);
          _isLoading = false;
        });
      }
    }

    // 2. Sync with API
    final token = await _authService.getToken();
    if (token != null) {
      final apiUser = await _apiService.getProfile(token);
      if (apiUser != null) {
        // Update Cache
        await _databaseService.saveCurrentUser(apiUser);
        if (mounted) {
          setState(() {
            _currentUser = apiUser;
            _updateLocalStateFromUser(apiUser);
            _isLoading = false;
          });
        }
      }
    }
  }

  void _updateLocalStateFromUser(User user) {
    _showLastSeen = user.showLastSeen;
    _showProfilePhoto = user.showProfilePhoto;
    _showReadReceipts = user.showReadReceipts;
    _showStatus = user.showStatus;
  }

  Future<void> _updateSetting(String key, bool value) async {
    // Optimistic Update
    setState(() {
      if (key == 'show_last_seen') _showLastSeen = value;
      if (key == 'show_profile_photo') _showProfilePhoto = value;
      if (key == 'show_read_receipts') _showReadReceipts = value;
      if (key == 'show_status') _showStatus = value;
    });

    final token = await _authService.getToken();
    if (token != null) {
      final updatedUser = await _apiService.updateProfile(token, {key: value});
      if (updatedUser != null) {
        await _databaseService.saveCurrentUser(updatedUser);
      } else {
        // Revert on failure
        if (mounted) {
          setState(() {
            // Revert logic (simplified)
             _loadSettings(); // Reload to reset state
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update setting')),
          );
        }
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
          'Privacy',
          style: GoogleFonts.outfit(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator()) 
          : ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(
            'Who can see my personal info',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            context,
            icon: Icons.access_time,
            title: 'Last Seen',
            subtitle: 'Show when you were last online',
            value: _showLastSeen,
            color: Color(0xFF6366F1), // Indigo
            onChanged: (value) => _updateSetting('show_last_seen', value),
          ),
          
          _buildSwitchTile(
            context,
            icon: Icons.account_circle,
            title: 'Profile Photo',
            subtitle: 'Show your profile photo to contacts',
            value: _showProfilePhoto,
            color: Color(0xFF10B981), // Emerald
            onChanged: (value) => _updateSetting('show_profile_photo', value),
          ),
          
          _buildSwitchTile(
            context,
            icon: Icons.done_all,
            title: 'Read Receipts',
            subtitle: 'Show blue ticks when you read messages',
            value: _showReadReceipts,
            color: Color(0xFF3B82F6), // Blue
            onChanged: (value) => _updateSetting('show_read_receipts', value),
          ),
          
          _buildSwitchTile(
            context,
            icon: Icons.info_outline,
            title: 'Status',
            subtitle: 'Show your status message',
            value: _showStatus,
            color: Color(0xFFF59E0B), // Amber
            onChanged: (value) => _updateSetting('show_status', value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: theme.disabledColor,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
      ),
    );
  }
}