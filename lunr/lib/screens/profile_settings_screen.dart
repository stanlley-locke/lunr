import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  
  User? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    // 1. Load from Cache first
    try {
      final cachedUser = await _databaseService.getCurrentUser();
      if (mounted && cachedUser != null) {
        print('DEBUG: Loaded profile from cache');
        setState(() {
          _currentUser = cachedUser;
          _nameController.text = cachedUser.username;
          _aboutController.text = cachedUser.bio;
          _phoneController.text = cachedUser.phoneNumber ?? '';
          _isLoading = false; // Show cached data immediately
        });
      }
    } catch (e) {
      print('Error loading cached profile: $e');
    }

    // 2. Fetch from Network
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final user = await _apiService.getProfile(token);
        if (mounted && user != null) {
          print('DEBUG: Loaded profile from network');
          setState(() {
            _currentUser = user;
            _nameController.text = user.username;
            _aboutController.text = user.bio;
            _phoneController.text = user.phoneNumber ?? '';
            _isLoading = false;
          });
          // 3. Update Cache
          await _databaseService.saveCurrentUser(user);
        }
      }
    } catch (e) {
      print('Error loading network profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      _cropImage(pickedFile.path);
    }
  }

  Future<void> _cropImage(String filePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Edit Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      await _uploadImage(File(croppedFile.path));
    }
  }

  Future<void> _uploadImage(File file) async {
    if (_currentUser == null) return;
    
    setState(() => _isSaving = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        // 1. Upload Image
        final imageUrl = await _apiService.uploadMedia(token, file, mediaType: 'image');
        
        if (imageUrl != null) {
           // 2. Update Profile with new Avatar URL
           final updatedUser = await _apiService.updateProfile(token, {
             'username': _currentUser!.username, // Keep existing
             'avatar': imageUrl,
           });
           
           if (mounted && updatedUser != null) {
             setState(() => _currentUser = updatedUser);
             await _databaseService.saveCurrentUser(updatedUser);
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Profile photo updated successfully')),
             );
           }
        } else {
           throw Exception('Upload failed');
        }
      }
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    
    setState(() => _isSaving = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final updatedUser = await _apiService.updateProfile(token, {
          'username': _nameController.text.trim(),
          'bio': _aboutController.text.trim(),
          'phone_number': _phoneController.text.trim(),
        });
        
        if (mounted && updatedUser != null) {
           setState(() => _currentUser = updatedUser);
           // Update Cache
           await _databaseService.saveCurrentUser(updatedUser);
           
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Profile updated successfully')),
           );
           Navigator.pop(context); 
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showQrCode() {
    if (_currentUser == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'My QR Code',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _currentUser!.username, // Or a deep link scheme
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '@${_currentUser!.username}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Scan to add me on Lunr',
                style: GoogleFonts.inter(
                  color: Theme.of(context).disabledColor,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 24),
              CustomButton(
                text: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text('Profile'), backgroundColor: theme.scaffoldBackgroundColor, elevation: 0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          'Profile',
          style: GoogleFonts.outfit(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving 
              ? SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : Text(
                  'Save',
                  style: GoogleFonts.inter(
                    color: theme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Photo Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      backgroundImage: (_currentUser?.avatar != null && _currentUser!.avatar!.startsWith('http')) 
                        ? CachedNetworkImageProvider(_currentUser!.avatar!) 
                        : null,
                      child: (_currentUser?.avatar == null || !_currentUser!.avatar!.startsWith('http')) 
                        ? Text(
                            (_currentUser?.username ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: theme.primaryColor,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40),
            
            // Name Field
            CustomTextField(
              controller: _nameController,
              label: 'Name / Username',
              hint: 'Enter your username',
              prefixIcon: Icon(Icons.person_outline, color: theme.primaryColor),
            ),
            
            SizedBox(height: 20),
            
            // About Field
            CustomTextField(
              controller: _aboutController,
              label: 'About',
              hint: 'Tell us about yourself',
              prefixIcon: Icon(Icons.info_outline, color: theme.primaryColor),
              maxLines: 3,
            ),
            
            SizedBox(height: 20),
            
            // Phone Field
            CustomTextField(
              controller: _phoneController,
              label: 'Phone',
              hint: 'Your phone number',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset(
                  'assets/icons/lunr_phone_icon.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Additional Options
            _buildSettingsTile(
              context,
              icon: Icons.qr_code,
              title: 'QR Code',
              subtitle: 'Share your QR code with others',
              color: Color(0xFF6366F1), // Indigo
              onTap: _showQrCode,
            ),
            
            // NOTE: 'Username' link is somewhat redundant if 'Name' field is the username.
            // But if 'Name' becomes display name later, this would be valuable.
            // For now, I'll keep it but make it focus the Name field or show info.
            _buildSettingsTile(
              context,
              icon: Icons.link,
              title: 'Username',
              subtitle: '@${_currentUser?.username ?? "username"}',
              color: Color(0xFF10B981), // Emerald
              onTap: () {
                 // Scroll to top or show info
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit your username in the Name field above.')));
              },
            ),
          ],
        ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}