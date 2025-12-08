import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_app_bar.dart';
import 'privacy_settings_screen.dart';
import 'security_settings_screen.dart';
import 'blocked_contacts_screen.dart';
import 'delete_account_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Account',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Last seen, read receipts, profile photo',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacySettingsScreen())),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Change password',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SecuritySettingsScreen())),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.block_outlined,
            title: 'Blocked Contacts',
            subtitle: 'Manage blocked users',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BlockedContactsScreen())),
          ),
          SizedBox(height: 24),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            color: Colors.red,
            textColor: Colors.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeleteAccountScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    Color? textColor,
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
                    color: (color ?? theme.primaryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color ?? theme.primaryColor,
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
                          color: textColor ?? theme.textTheme.bodyLarge?.color,
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