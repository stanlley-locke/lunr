import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'chat_list_screen.dart';
import 'groups_screen.dart';
import 'updates_screen.dart';
import 'tools_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    ChatListScreen(),
    GroupsScreen(),
    UpdatesScreen(),
    ToolsScreen(),
    SettingsScreen(),
  ];

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
    {
      'icon': 'assets/icons/lunr_settings_icon.png',
      'label': 'Settings',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xFF2196F3),
            unselectedItemColor: themeProvider.subtitleColor,
            backgroundColor: themeProvider.cardColor,
            elevation: 0,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            items: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              return BottomNavigationBarItem(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: index == _currentIndex 
                        ? Color(0xFF2196F3).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    item['icon'],
                    width: 24,
                    height: 24,
                    color: index == _currentIndex 
                        ? Color(0xFF2196F3)
                        : themeProvider.subtitleColor,
                  ),
                ),
                label: item['label'],
              );
            }),
          ),
        ),
      ),
    );
  }
}