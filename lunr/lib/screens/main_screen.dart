import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'chat_list_screen.dart';
import 'groups_screen.dart';
import 'updates_screen.dart';
import 'tools_screen.dart';
import 'settings_screen.dart';
import 'profile_settings_screen.dart';

import 'privacy_settings_screen.dart';
import 'login_screen.dart';
import 'contacts_screen.dart';
import '../services/permission_service.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  int _groupUnreadCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _currentUser;
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadUserProfile();
    _screens = [
      ChatListScreen(
        onMenuPressed: _openDrawer,
        onUnreadCountChanged: (count) {
          if (mounted) setState(() => _unreadCount = count);
        },
      ),
      GroupsScreen(
        onMenuPressed: _openDrawer,
        onUnreadCountChanged: (count) {
          if (mounted) setState(() => _groupUnreadCount = count);
        },
      ),
      UpdatesScreen(onMenuPressed: _openDrawer),
      ToolsScreen(onMenuPressed: _openDrawer),
    ];
  }

  Future<void> _loadUserProfile() async {
    final token = await _authService.getToken();
    print('DEBUG: Loading profile, token: ${token != null}');
    if (token != null) {
      final user = await _apiService.getProfile(token);
      print('DEBUG: Profile fetched: ${user?.username}');
      if (mounted && user != null) {
        setState(() => _currentUser = user);
      }
    } else {
        print('DEBUG: No token found');
    }
  }

  Future<void> _requestPermissions() async {
    await PermissionService().requestInitialPermissions();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': 'assets/icons/lunr_chats_icon.png',
      'label': 'Chats',
    },
    {
      'icon': 'assets/icons/lunr_group_icon.png',
      'label': 'Groups',
    },
    {
      'icon': 'assets/icons/lunr_updates_icon.png',
      'label': 'Updates',
    },
    {
      'icon': 'assets/icons/lunr_tools_icon.png',
      'label': 'Tools',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, theme),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = _navItems[index];
                
                return InkWell(
                  onTap: () => setState(() => _currentIndex = index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              item['icon'],
                              width: 24,
                              height: 24,
                              // color: isSelected ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.5),
                            ),
                            if ((index == 0 && _unreadCount > 0) || (index == 1 && _groupUnreadCount > 0))
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index == 0 ? _unreadCount : _groupUnreadCount}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          item['label'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? theme.primaryColor : theme.iconTheme.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // User Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    backgroundImage: _currentUser?.avatar != null ? NetworkImage(_currentUser!.avatar!) : null,
                    child: _currentUser?.avatar == null 
                      ? Text(
                          (_currentUser?.username ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ) 
                      : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.username ?? 'Loading...',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.disabledColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Menu Items
          _buildDrawerItem(
            context,
            icon: 'assets/icons/lunr_profile_icon.png',
            title: 'Profile',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSettingsScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: 'assets/icons/lunr_contacts_icon.png',
            title: 'Contacts',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactsScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: 'assets/icons/lunr_settings_icon.png',
            title: 'Settings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: 'assets/icons/lunr_privacy_icon.png',
            title: 'Privacy',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacySettingsScreen())),
          ),
          _buildDrawerItem(
            context,
            icon: 'assets/icons/lunr_help_support_icon.png',
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Help Center coming soon!')));
            },
          ),
          
          Spacer(),
          
           // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Divider(color: theme.dividerColor),
          ),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            leading: Icon(Icons.logout_rounded, color: Colors.red),
            title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.red)),
            onTap: () async {
               await _authService.logout();
               Navigator.pushAndRemoveUntil(
                 context, 
                 MaterialPageRoute(builder: (_) => LoginScreen()),
                 (route) => false
               );
            },
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required String icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Image.asset(icon, width: 24, height: 24),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
      ),
    );
  }
}