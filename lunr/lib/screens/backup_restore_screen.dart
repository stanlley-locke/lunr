import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  @override
  _BackupRestoreScreenState createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  // Backup Options
  bool _backupSettings = true;
  bool _backupProfile = true;
  bool _backupContacts = true;
  bool _backupChats = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performBackup() async {
    setState(() => _isProcessing = true);
    
    List<String> include = [];
    if (_backupSettings) include.add('settings');
    if (_backupProfile) include.add('profile');
    if (_backupContacts) include.add('contacts');
    if (_backupChats) include.add('chats'); // 'chats' maps to 'chat_rooms' in backend logic effectively via 'all' or explicit check

    final token = await _authService.getToken();
    if (token != null) {
      final data = await _apiService.backupData(token, include: include);
      
      if (data != null) {
        try {
          String jsonString = jsonEncode(data);
          Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
          
          // Generate filename with date
          String date = DateTime.now().toIso8601String().split('T')[0];
          String name = 'lunr_backup_$date';
          
          // Save file (using positional args for compatibility)
          if (Platform.isAndroid || Platform.isIOS) {
             await FileSaver.instance.saveFile(name, bytes, 'json', mimeType: MimeType.json);
          } else {
             await FileSaver.instance.saveFile(name, bytes, 'json', mimeType: MimeType.json);
          }
          
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved successfully')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving backup: $e')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch backup data')));
      }
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _performRestore() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        setState(() => _isProcessing = true);
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(content);

        final token = await _authService.getToken();
        if (token != null) {
          bool success = await _apiService.restoreData(token, data);
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore completed successfully')));
          } else {
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed at backend')));
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error restoring: $e')));
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Backup & Restore', style: theme.textTheme.titleLarge),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: theme.primaryColor,
          tabs: [
            Tab(text: 'Backup'),
            Tab(text: 'Restore'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBackupTab(theme),
          _buildRestoreTab(theme),
        ],
      ),
    );
  }

  Widget _buildBackupTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select data to backup:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          CheckboxListTile(
            title: Text('Settings'),
            value: _backupSettings,
            onChanged: (v) => setState(() => _backupSettings = v!),
            activeColor: theme.primaryColor,
          ),
          CheckboxListTile(
            title: Text('User Profile'),
            value: _backupProfile,
            onChanged: (v) => setState(() => _backupProfile = v!),
            activeColor: theme.primaryColor,
          ),
          CheckboxListTile(
            title: Text('Contacts'),
            value: _backupContacts,
            onChanged: (v) => setState(() => _backupContacts = v!),
            activeColor: theme.primaryColor,
          ),
          CheckboxListTile(
            title: Text('Chats & Messages'),
            value: _backupChats,
            onChanged: (v) => setState(() => _backupChats = v!),
            activeColor: theme.primaryColor,
          ),
          Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _performBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Create Backup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restore_page_outlined, size: 80, color: theme.primaryColor),
          SizedBox(height: 24),
          Text(
            'Restore from Backup',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Select a previously generated backup file (.json) to restore your data.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
          ),
          SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _performRestore,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.upload_file, color: Colors.white),
              label: _isProcessing 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Select Backup File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
