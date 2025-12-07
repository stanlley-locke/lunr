import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'chat_settings_screen.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
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
              'assets/icons/lunr_settings_icon.png',
              width: 24,
              height: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF2196F3),
                  child: Text(
                    'U',
                    style: TextStyle(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Available',
                        style: TextStyle(
                          color: themeProvider.subtitleColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: themeProvider.subtitleColor,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Settings Options
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_profile_icon.png',
            title: 'Account',
            subtitle: 'Privacy, security, change number',
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrivacySettingsScreen()),
              );
            },
          ),
          
          // Theme Switcher
          Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              secondary: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
              subtitle: Text(
                'Switch app theme',
                style: TextStyle(
                  color: themeProvider.subtitleColor,
                  fontSize: 14,
                ),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: Color(0xFF2196F3),
            ),
          ),
          
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_help_support_icon.png',
            title: 'Help',
            subtitle: 'Help center, contact us, privacy policy',
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
                  style: TextStyle(
                    color: themeProvider.subtitleColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            icon,
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: themeProvider.subtitleColor,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: themeProvider.subtitleColor,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: themeProvider.subtitleColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.subtitleColor),
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
                elevation: 8,
                shadowColor: Colors.red.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}