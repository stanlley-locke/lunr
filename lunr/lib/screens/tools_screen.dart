import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ToolsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tools = [
    {
      'name': 'QR Code Scanner',
      'description': 'Scan QR codes to quickly add contacts or join groups',
      'icon': Icons.qr_code_scanner,
      'color': Colors.blue,
    },
    {
      'name': 'Voice Recorder',
      'description': 'Record and send voice messages',
      'icon': Icons.mic,
      'color': Colors.green,
    },
    {
      'name': 'Location Sharing',
      'description': 'Share your current location with contacts',
      'icon': Icons.location_on,
      'color': Colors.red,
    },
    {
      'name': 'File Manager',
      'description': 'Manage and share files from your device',
      'icon': Icons.folder,
      'color': Colors.orange,
    },
    {
      'name': 'Backup & Restore',
      'description': 'Backup your chats and restore them on new devices',
      'icon': Icons.backup,
      'color': Colors.purple,
    },
    {
      'name': 'Theme Customizer',
      'description': 'Customize app appearance with themes and colors',
      'icon': Icons.palette,
      'color': Colors.pink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.backgroundColor,
        elevation: 8,
        shadowColor: themeProvider.isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
        title: Row(
          children: [
            Image.asset(
              'assets/icons/lunr_tools_icon.png',
              width: 24,
              height: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Tools',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _buildToolCard(
            context,
            name: tool['name'],
            description: tool['description'],
            icon: tool['icon'],
            color: tool['color'],
          );
        },
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name coming soon!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: themeProvider.cardColor,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 6),
                Flexible(
                  flex: 2,
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}