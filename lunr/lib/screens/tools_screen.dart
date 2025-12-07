import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_app_bar.dart';

class ToolsScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  ToolsScreen({Key? key, this.onMenuPressed}) : super(key: key);

  final List<Map<String, dynamic>> tools = [
    {
      'name': 'QR Code Scanner',
      'description': 'Scan QR codes to quickly add contacts or join groups',
      'icon': Icons.qr_code_scanner,
      'color': Color(0xFF6366F1), // Indigo
    },
    {
      'name': 'Voice Recorder',
      'description': 'Record and send voice messages',
      'icon': Icons.mic,
      'color': Color(0xFF10B981), // Emerald
    },
    {
      'name': 'Location Sharing',
      'description': 'Share your current location with contacts',
      'image': 'assets/icons/lunr_location_icon.png',
      'color': Color(0xFFEF4444), // Red
    },
    {
      'name': 'File Manager',
      'description': 'Manage and share files from your device',
      'icon': Icons.folder,
      'color': Color(0xFFF59E0B), // Amber
    },
    {
      'name': 'Backup & Restore',
      'description': 'Backup your chats and restore them on new devices',
      'icon': Icons.backup,
      'color': Color(0xFF8B5CF6), // Violet
    },
    {
      'name': 'Theme Customizer',
      'description': 'Customize app appearance with themes and colors',
      'icon': Icons.palette,
      'color': Color(0xFFEC4899), // Pink
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Tools',
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              'assets/icons/lunr_humburger_icon.png',
              width: 24,
              height: 24,
              // color: theme.iconTheme.color, // Removed to preserve 3D effect
            ),
            onPressed: onMenuPressed,
          ),
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
            image: tool['image'],
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
    IconData? icon,
    String? image,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name coming soon!', style: GoogleFonts.inter()),
                behavior: SnackBarBehavior.floating,
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsets.all(16),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: image != null
                      ? Image.asset(
                          image,
                          width: 32,
                          height: 32,
                          // color: color, // Removed to preserve 3D effect
                        )
                      : Icon(
                          icon,
                          size: 32,
                          color: color,
                        ),
                ),
                SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.disabledColor,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}