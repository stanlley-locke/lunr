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

  List<dynamic> _cloudBackups = [];
  bool _loadingBackups = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCloudBackups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCloudBackups() async {
    if (!mounted) return;
    setState(() => _loadingBackups = true);
    final token = await _authService.getToken();
    if (token != null) {
      final backups = await _apiService.getCloudBackups(token);
      if (mounted) setState(() => _cloudBackups = backups);
    }
    if (mounted) setState(() => _loadingBackups = false);
  }
  
  Future<void> _performCloudBackup() async {
     setState(() => _isProcessing = true);
     final token = await _authService.getToken();
     if (token != null) {
       final success = await _apiService.createCloudBackup(token);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Cloud backup created' : 'Failed to create backup')));
         if (success) _loadCloudBackups();
       }
     }
     if (mounted) setState(() => _isProcessing = false);
  }
  
  Future<void> _restoreCloudBackup(String id) async {
     setState(() => _isProcessing = true);
     final token = await _authService.getToken();
     if (token != null) {
       final success = await _apiService.restoreCloudBackup(token, id);
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Restore completed' : 'Restore failed')));
     }
     if (mounted) setState(() => _isProcessing = false);
  }
  
  Future<void> _deleteCloudBackup(String id) async {
    final token = await _authService.getToken();
    if (token != null) {
      final success = await _apiService.deleteCloudBackup(token, id);
      if (success) _loadCloudBackups();
    }
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
          
          // Save file (ext removed based on compilation feedback)
          if (Platform.isAndroid || Platform.isIOS) {
             await FileSaver.instance.saveFile(name: '$name.json', bytes: bytes, mimeType: MimeType.json);
          } else {
             await FileSaver.instance.saveFile(name: '$name.json', bytes: bytes, mimeType: MimeType.json);
          }
          
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File backup saved')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch data')));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cloud Backup Section
          Text('Cloud Backup', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Save your data securely to the cloud.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _performCloudBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.cloud_upload, color: Colors.white),
              label: _isProcessing 
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Back Up Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          
          Divider(height: 48),
          
          // Local Backup Section
          Text('Local File Backup', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Select data to export to a file:', style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor)),
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
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _performBackup, // This is the file backup
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.save_alt, color: theme.primaryColor),
              label: Text('Export to File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreTab(ThemeData theme) {
    return Column(
      children: [
        // Cloud Backups List
        Expanded(
          child: _loadingBackups 
            ? Center(child: CircularProgressIndicator())
            : _cloudBackups.isEmpty 
                ? Center(child: Text('No cloud backups found', style: TextStyle(color: theme.disabledColor)))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _cloudBackups.length,
                    itemBuilder: (context, index) {
                      final backup = _cloudBackups[index];
                      // Format date
                      final dateStr = backup['created_at'] ?? '';
                      // Size
                      final size = backup['size_bytes'] ?? 0;
                      final sizeStr = (size / 1024).toStringAsFixed(1) + ' KB';
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.cloud_done, color: theme.primaryColor),
                          title: Text('Backup: $dateStr'), // Enhance date formatting if time permits
                          subtitle: Text('Size: $sizeStr'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.restore, color: Colors.green),
                                onPressed: _isProcessing ? null : () => _restoreCloudBackup(backup['id']),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: _isProcessing ? null : () => _deleteCloudBackup(backup['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
        Divider(),
        // Restore from File option
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isProcessing ? null : _performRestore, // Existing file restore method
              icon: Icon(Icons.upload_file),
              label: Text('Restore from Local File'),
            ),
          ),
        ),
      ],
    );
  }
}
