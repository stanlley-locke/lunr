import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountSettingsScreen extends StatelessWidget {
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
          'Account',
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
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_privacy_icon.png',
            title: 'Privacy',
            subtitle: 'Last seen, profile photo, about',
            color: Color(0xFF6366F1), // Indigo
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Security',
            subtitle: 'End-to-end encryption, login alerts',
            color: Color(0xFF10B981), // Emerald
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: 'assets/icons/lunr_profile_icon.png',
            title: 'Avatar',
            subtitle: 'Create, edit, profile photo',
            color: Color(0xFFF59E0B), // Amber
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.block,
            title: 'Blocked contacts',
            subtitle: 'Manage blocked users',
            color: Color(0xFFEF4444), // Red
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline,
            title: 'Delete my account',
            subtitle: 'Delete account and erase your data',
            color: Colors.red,
            isDestructive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required dynamic icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
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
                    color: (isDestructive ? Colors.red : color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: icon is String
                      ? Image.asset(
                          icon,
                          width: 24,
                          height: 24,
                          // color: isDestructive ? Colors.red : color, // Removed to preserve 3D effect
                        )
                      : Icon(
                          icon,
                          size: 24,
                          color: isDestructive ? Colors.red : color,
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
                          color: isDestructive ? Colors.red : theme.textTheme.bodyLarge?.color,
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