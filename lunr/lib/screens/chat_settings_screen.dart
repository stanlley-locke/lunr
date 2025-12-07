import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          'Chats',
          style: GoogleFonts.outfit(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          Text(
            'Display',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSettingsTile(
            context,
            icon: Icons.wallpaper,
            title: 'Wallpaper',
            subtitle: 'Change chat background',
            color: Color(0xFF6366F1), // Indigo
            onTap: () {},
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.text_fields,
            title: 'Font size',
            subtitle: 'Small, Normal, Large, Extra Large',
            color: Color(0xFF10B981), // Emerald
            onTap: () {},
          ),
          
          SizedBox(height: 32),
          
          Text(
            'Media',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            context,
            icon: Icons.download,
            title: 'Auto-download media',
            subtitle: 'Automatically download photos and videos',
            value: _autoDownloadMedia,
            color: Color(0xFF3B82F6), // Blue
            onChanged: (value) {
              setState(() {
                _autoDownloadMedia = value;
              });
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.photo_library,
            title: 'Media visibility',
            subtitle: 'Show media in gallery',
            color: Color(0xFFF59E0B), // Amber
            onTap: () {},
          ),
          
          SizedBox(height: 32),
          
          Text(
            'Backup',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            context,
            icon: Icons.backup,
            title: 'Chat backup',
            subtitle: 'Back up your chats to cloud storage',
            value: _backupEnabled,
            color: Color(0xFF8B5CF6), // Violet
            onChanged: (value) {
              setState(() {
                _backupEnabled = value;
              });
            },
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.history,
            title: 'Chat history',
            subtitle: 'Export, delete, or clear chat history',
            color: Color(0xFFEF4444), // Red
            onTap: () {},
          ),
          
          SizedBox(height: 32),
          
          Text(
            'Advanced',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSettingsTile(
            context,
            icon: Icons.archive,
            title: 'Archived chats',
            subtitle: 'View archived conversations',
            color: Color(0xFF64748B), // Slate
            onTap: () {},
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'App language',
            subtitle: 'English (device language)',
            color: Color(0xFFEC4899), // Pink
            onTap: () {},
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
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
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
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
}