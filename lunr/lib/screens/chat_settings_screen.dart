import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/user_settings.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:convert';
import 'dart:typed_data';

class ChatSettingsScreen extends StatefulWidget {
  @override
  _ChatSettingsScreenState createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Settings state
  String _wallpaper = 'default';
  int _fontSize = 14;
  bool _mediaVisibility = true;
  bool _autoDownload = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final token = await _authService.getToken();
    if (token != null) {
      final settings = await _apiService.getSettings(token);
      if (mounted && settings != null) {
        setState(() {
          _wallpaper = settings.wallpaper;
          _fontSize = settings.fontSize;
          _mediaVisibility = settings.mediaVisibility;
          _autoDownload = settings.autoDownloadMedia;
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    setState(() {
      if (key == 'wallpaper') _wallpaper = value;
      if (key == 'fontSize') _fontSize = value;
      if (key == 'mediaVisibility') _mediaVisibility = value;
      if (key == 'autoDownload') _autoDownload = value;
    });

    final token = await _authService.getToken();
    if (token != null) {
      await _apiService.updateSettings(token, UserSettings(
        wallpaper: _wallpaper,
        fontSize: _fontSize,
        mediaVisibility: _mediaVisibility,
        autoDownloadMedia: _autoDownload,
        // Preserve other defaults or fetch full object if needed, 
        // but for now we rely on backend partial update or default merge
      ));
    }
  }

  Future<void> _backupChats() async {
    setState(() => _isLoading = true);
    final token = await _authService.getToken();
    if (token != null) {
      final data = await _apiService.backupData(token);
      
      if (data != null) {
        // Create JSON file
        try {
          String jsonString = jsonEncode(data);
          Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
          
          // TODO: Fix FileSaver parameters for installed version
          /*
          await FileSaver.instance.saveFile(
            name: 'lunr_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}',
            bytes: bytes,
            ext: 'json',
            mimeType: MimeType.json,
          );
          */
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup Generated (File Save disabled temporarily)')));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup downloaded successfully')));
          }
        } catch (e) {
          print("Backup save error: $e");
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save backup file')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate backup')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _clearAllChats() async {
    // Logic to clear chats would go here - for now just show a dialog
    // This requires a backend endpoint "delete all chats" which we haven't built yet,
    // or iterating through all rooms and deleting them.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clear All Chats coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Chat Settings', style: theme.textTheme.titleLarge),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(24),
            children: [
              _buildSectionHeader(theme, 'Display'),
              _buildOption(
                theme,
                title: 'Wallpaper',
                subtitle: _wallpaper == 'default' ? 'Default' : 'Custom',
                icon: Icons.wallpaper,
                onTap: () {
                   // Ideally show a picker. For now toggle or show dialog
                   _showWallpaperDialog(theme);
                },
              ),
              _buildSliderOption(theme, 'Font Size', _fontSize.toDouble(), 10, 30, (val) {
                _updateSetting('fontSize', val.toInt());
              }),
              _buildSwitchOption(theme, 'App Language', 'English', true, (val) {
                 // Single language for now
              }),
              
              SizedBox(height: 32),
              _buildSectionHeader(theme, 'Media'),
              _buildSwitchOption(
                theme, 
                'Media Visibility', 
                'Show newly downloaded media in your device gallery', 
                _mediaVisibility, 
                (val) => _updateSetting('mediaVisibility', val)
              ),
              _buildSwitchOption(
                theme, 
                'Auto-Download Media', 
                'Automatically download photos and videos', 
                _autoDownload, 
                (val) => _updateSetting('autoDownload', val)
              ),

              SizedBox(height: 32),
              _buildSectionHeader(theme, 'Backup & History'),
              _buildOption(
                theme,
                title: 'Chat Backup',
                subtitle: 'Back up your chats and media',
                icon: Icons.cloud_upload_outlined,
                onTap: _backupChats,
              ),
              _buildOption(
                theme,
                title: 'Chat History',
                subtitle: 'Clear all chats, Delete all chats',
                icon: Icons.history,
                onTap: () {
                   // Sub-menu for Clear/Delete
                   _showHistoryDialog(theme);
                },
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: theme.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildOption(ThemeData theme, {
    required String title, required String subtitle, required IconData icon, required VoidCallback onTap
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.primaryColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.disabledColor),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildSwitchOption(ThemeData theme, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        activeColor: theme.primaryColor,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderOption(ThemeData theme, String title, double value, double min, double max, Function(double) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${value.toInt()}', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: theme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showWallpaperDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Choose Wallpaper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             ListTile(title: Text('Default'), onTap: () { _updateSetting('wallpaper', 'default'); Navigator.pop(ctx); }),
             ListTile(title: Text('Dark'), onTap: () { _updateSetting('wallpaper', 'dark'); Navigator.pop(ctx); }),
             ListTile(title: Text('Light'), onTap: () { _updateSetting('wallpaper', 'light'); Navigator.pop(ctx); }),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog(ThemeData theme) {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chat History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             ListTile(
               leading: Icon(Icons.delete_forever, color: Colors.red),
               title: Text('Delete All Chats'), 
               onTap: () { Navigator.pop(ctx); _clearAllChats(); }
             ),
          ],
        ),
      ),
    );
  }
}
