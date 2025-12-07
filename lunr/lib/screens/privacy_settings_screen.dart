import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showLastSeen = true;
  bool _showProfilePhoto = true;
  bool _showReadReceipts = true;
  bool _showStatus = true;

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
          'Privacy',
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
            'Who can see my personal info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSwitchTile(
            icon: Icons.access_time,
            title: 'Last Seen',
            subtitle: 'Show when you were last online',
            value: _showLastSeen,
            onChanged: (value) {
              setState(() {
                _showLastSeen = value;
              });
            },
          ),
          
          _buildSwitchTile(
            icon: Icons.account_circle,
            title: 'Profile Photo',
            subtitle: 'Show your profile photo to contacts',
            value: _showProfilePhoto,
            onChanged: (value) {
              setState(() {
                _showProfilePhoto = value;
              });
            },
          ),
          
          _buildSwitchTile(
            icon: Icons.done_all,
            title: 'Read Receipts',
            subtitle: 'Show blue ticks when you read messages',
            value: _showReadReceipts,
            onChanged: (value) {
              setState(() {
                _showReadReceipts = value;
              });
            },
          ),
          
          _buildSwitchTile(
            icon: Icons.info_outline,
            title: 'Status',
            subtitle: 'Show your status message',
            value: _showStatus,
            onChanged: (value) {
              setState(() {
                _showStatus = value;
              });
            },
          ),
          
          SizedBox(height: 24),
          
          Text(
            'Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSettingsTile(
            icon: Icons.block,
            title: 'Blocked Contacts',
            subtitle: 'Manage blocked users',
            onTap: () {},
          ),
          
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Two-Step Verification',
            subtitle: 'Add extra security to your account',
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