import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'profile_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'chat_settings_screen.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _currentUser;
  final ApiService _apiService = ApiService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // 1. Load from Local DB first
    final localUser = await _databaseService.getCurrentUser();
    if (mounted && localUser != null) {
      setState(() => _currentUser = localUser);
    }

    // 2. Sync with API
    final token = await _authService.getToken();
    if (token != null) {
      try {
        final user = await _apiService.getProfile(token);
        if (mounted && user != null) {
          await _databaseService.saveCurrentUser(user);
          setState(() => _currentUser = user);
        }
      } catch (e) {
        print('Error refreshing profile in settings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Settings',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: EdgeInsets.all(20),
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
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileSettingsScreen()),
                );
                // Refresh profile on return
                _loadProfile();
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.primaryColor,
                    backgroundImage: (_currentUser?.avatar != null && _currentUser!.avatar!.startsWith('http')) 
                      ? CachedNetworkImageProvider(_currentUser!.avatar!) 
                      : null,
                    child: (_currentUser?.avatar == null || !_currentUser!.avatar!.startsWith('http'))
                      ? Text(
                          (_currentUser?.username ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.username ?? 'Loading...',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          (_currentUser?.statusMessage != null && _currentUser!.statusMessage.isNotEmpty)
                              ? _currentUser!.statusMessage
                              : 'Available',
                          style: GoogleFonts.inter(
                            color: theme.disabledColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.disabledColor,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Settings Options
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_profile_icon.png',
            title: 'Account',
            subtitle: 'Privacy, security, change number',
            color: Color(0xFF6366F1), // Indigo
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AccountSettingsScreen()),
              );
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_chats_icon.png',
            title: 'Chats',
            subtitle: 'Theme, wallpapers, chat history',
            color: Color(0xFF10B981), // Emerald
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatSettingsScreen()),
              );
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_notification_icon.png',
            title: 'Notifications',
            subtitle: 'Message, group & call tones',
            color: Color(0xFFEF4444), // Red
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsSettingsScreen()),
              );
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_privacy_icon.png',
            title: 'Privacy',
            subtitle: 'Block contacts, disappearing messages',
            color: Color(0xFFF59E0B), // Amber
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrivacySettingsScreen()),
              );
            },
          ),
          
          // Theme Switcher
          Container(
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
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              secondary: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.1), // Violet
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              title: Text(
                'Dark Mode',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                'Switch app theme',
                style: GoogleFonts.inter(
                  color: theme.disabledColor,
                  fontSize: 14,
                ),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: theme.primaryColor,
            ),
          ),
          
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_help_support_icon.png',
            title: 'Help',
            subtitle: 'Help center, contact us, privacy policy',
            color: Color(0xFFEC4899), // Pink
            onTap: () {
              // Navigate to help
            },
          ),
          
          SizedBox(height: 32),
          
          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'Lunr v2.1.0',
                  style: GoogleFonts.inter(
                    color: theme.disabledColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    icon,
                    width: 24,
                    height: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: theme.disabledColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.disabledColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.inter(color: theme.textTheme.bodyMedium?.color),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: theme.disabledColor),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}