import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'profile_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'chat_settings_screen.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Settings',
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              'assets/icons/lunr_humburger_icon.png',
              width: 24,
              height: 24,
              color: theme.iconTheme.color,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileSettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      'U',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Username',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Available',
                          style: GoogleFonts.inter(
                            color: theme.disabledColor,
                            fontSize: 14,
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
                    // color: color, // Removed to preserve 3D effect
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