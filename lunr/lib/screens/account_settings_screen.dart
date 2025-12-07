import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatelessWidget {
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
          'Account',
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
          _buildSettingsTile(
            icon: 'assets/icons/lunr_privacy_icon.png',
            title: 'Privacy',
            subtitle: 'Last seen, profile photo, about',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'End-to-end encryption, login alerts',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: 'assets/icons/lunr_profile_icon.png',
            title: 'Avatar',
            subtitle: 'Create, edit, profile photo',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.block,
            title: 'Blocked contacts',
            subtitle: 'Manage blocked users',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete my account',
            subtitle: 'Delete account and erase your data',
            onTap: () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
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
            color: (isDestructive ? Colors.red : Color(0xFF2196F3)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon is String
              ? Image.asset(
                  icon,
                  width: 24,
                  height: 24,
                  color: isDestructive ? Colors.red : Color(0xFF2196F3),
                )
              : Icon(
                  icon,
                  size: 24,
                  color: isDestructive ? Colors.red : Color(0xFF2196F3),
                ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : Colors.black,
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