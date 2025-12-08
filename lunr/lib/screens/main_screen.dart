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

import '../services/permission_service.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _screens = [
      ChatListScreen(
        onMenuPressed: _openDrawer,
        onUnreadCountChanged: (count) {
          if (mounted) setState(() => _unreadCount = count);
        },
      ),
      GroupsScreen(onMenuPressed: _openDrawer),
      UpdatesScreen(onMenuPressed: _openDrawer),
      ToolsScreen(onMenuPressed: _openDrawer),
    ];
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
                            if (index == 0 && _unreadCount > 0)
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
                                      '$_unreadCount',
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
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.cardColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/lunr_app_icon.png',
                    width: 60,
                    height: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Lunr',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Image.asset('assets/icons/lunr_profile_icon.png', width: 24),
            title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSettingsScreen()));
            },
          ),
          ListTile(
            leading: Image.asset('assets/icons/lunr_settings_icon.png', width: 24),
            title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}