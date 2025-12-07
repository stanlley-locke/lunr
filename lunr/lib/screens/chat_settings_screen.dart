import 'package:flutter/material.dart';

class ChatSettingsScreen extends StatefulWidget {
  @override
  _ChatSettingsScreenState createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _autoDownloadMedia = true;
  bool _backupEnabled = false;
  String _selectedTheme = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chats',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Display',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSettingsTile(
            icon: Icons.wallpaper,
            title: 'Wallpaper',
            subtitle: 'Change chat background',
            onTap: () {},
          ),
          
          _buildSettingsTile(
            icon: Icons.text_fields,
            title: 'Font size',
            subtitle: 'Small, Normal, Large, Extra Large',
            onTap: () {},
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Media',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            icon: Icons.download,
            title: 'Auto-download media',
            subtitle: 'Automatically download photos and videos',
            value: _autoDownloadMedia,
            onChanged: (value) {
              setState(() {
                _autoDownloadMedia = value;
              });
            },
          ),
          
          _buildSettingsTile(
            icon: Icons.photo_library,
            title: 'Media visibility',
            subtitle: 'Show media in gallery',
            onTap: () {},
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Backup',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            icon: Icons.backup,
            title: 'Chat backup',
            subtitle: 'Back up your chats to cloud storage',
            value: _backupEnabled,
            onChanged: (value) {
              setState(() {
                _backupEnabled = value;
              });
            },
          ),
          
          _buildSettingsTile(
            icon: Icons.history,
            title: 'Chat history',
            subtitle: 'Export, delete, or clear chat history',
            onTap: () {},
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Advanced',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSettingsTile(
            icon: Icons.archive,
            title: 'Archived chats',
            subtitle: 'View archived conversations',
            onTap: () {},
          ),
          
          _buildSettingsTile(
            icon: Icons.language,
            title: 'App language',
            subtitle: 'English (device language)',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF2196F3),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Color(0xFF2196F3),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }
}