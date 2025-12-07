import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_app_bar.dart';

class UpdatesScreen extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const UpdatesScreen({Key? key, this.onMenuPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Updates',
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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildUpdateCard(
            context,
            version: '2.1.0',
            title: 'Enhanced Group Chat Features',
            description: 'Added group creation, admin controls, and member management features.',
            date: 'Dec 6, 2025',
            isNew: true,
          ),
          _buildUpdateCard(
            context,
            version: '2.0.5',
            title: 'Message Reactions & Replies',
            description: 'Users can now react to messages with emojis and reply to specific messages.',
            date: 'Dec 1, 2025',
          ),
          _buildUpdateCard(
            context,
            version: '2.0.3',
            title: 'Privacy Controls Update',
            description: 'Enhanced privacy settings including read receipts, last seen, and profile visibility.',
            date: 'Nov 28, 2025',
          ),
          _buildUpdateCard(
            context,
            version: '2.0.2',
            title: 'Security Patch',
            description: 'Fixed potential security vulnerabilities in message encryption.',
            date: 'Nov 25, 2025',
            isCritical: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context, {
    required String version,
    required String title,
    required String description,
    required String date,
    bool isNew = false,
    bool isCritical = false,
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
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCritical 
                        ? Colors.red.withOpacity(0.1)
                        : theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    version,
                    style: GoogleFonts.inter(
                      color: isCritical ? Colors.red : theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isNew) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                Spacer(),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    color: theme.disabledColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}