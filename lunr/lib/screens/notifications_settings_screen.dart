import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  @override
  _NotificationsSettingsScreenState createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showPreview = true;

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
          'Notifications',
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
            'Message notifications',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            context,
            icon: 'assets/icons/lunr_notification_icon.png',
            title: 'Show notifications',
            subtitle: 'Get notified for new messages',
            value: _messageNotifications,
            color: Color(0xFF6366F1), // Indigo
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
            },
          ),
          
          _buildSwitchTile(
            context,
            icon: Icons.visibility,
            title: 'Show preview',
            subtitle: 'Show message content in notifications',
            value: _showPreview,
            color: Color(0xFF10B981), // Emerald
            onChanged: (value) {
              setState(() {
                _showPreview = value;
              });
            },
          ),
          
          SizedBox(height: 32),
          
          Text(
            'Group notifications',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            context,
            icon: 'assets/icons/lunr_group_icon.png',
            title: 'Group notifications',
            subtitle: 'Get notified for group messages',
            value: _groupNotifications,
            color: Color(0xFFF59E0B), // Amber
            onChanged: (value) {
              setState(() {
                _groupNotifications = value;
              });
            },
          ),
          
          SizedBox(height: 32),
          
          Text(
            'Sound & vibration',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            context,
            icon: Icons.volume_up,
            title: 'Sound',
            subtitle: 'Play sound for notifications',
            value: _soundEnabled,
            color: Color(0xFFEF4444), // Red
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          
          _buildSwitchTile(
            context,
            icon: Icons.vibration,
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            value: _vibrationEnabled,
            color: Color(0xFF8B5CF6), // Violet
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          
          SizedBox(height: 32),
          
          _buildSettingsTile(
            context,
            icon: Icons.music_note,
            title: 'Notification tone',
            subtitle: 'Default notification sound',
            color: Color(0xFFEC4899), // Pink
            onTap: () {},
          ),
          
          _buildSettingsTile(
            context,
            icon: Icons.schedule,
            title: 'Do not disturb',
            subtitle: 'Set quiet hours',
            color: Color(0xFF64748B), // Slate
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required dynamic icon,
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
          child: icon is String
              ? Image.asset(
                  icon,
                  width: 24,
                  height: 24,
                  color: color,
                )
              : Icon(
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