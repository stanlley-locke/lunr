import 'package:flutter/material.dart';

class UpdatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Updates'),
        leading: Container(
          margin: EdgeInsets.all(8),
          child: Image.asset(
            'assets/icons/lunr_updates_icon.png',
            width: 24,
            height: 24,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildUpdateCard(
            version: '2.1.0',
            title: 'Enhanced Group Chat Features',
            description: 'Added group creation, admin controls, and member management features.',
            date: 'Dec 6, 2025',
            isNew: true,
          ),
          _buildUpdateCard(
            version: '2.0.5',
            title: 'Message Reactions & Replies',
            description: 'Users can now react to messages with emojis and reply to specific messages.',
            date: 'Dec 1, 2025',
          ),
          _buildUpdateCard(
            version: '2.0.3',
            title: 'Privacy Controls Update',
            description: 'Enhanced privacy settings including read receipts, last seen, and profile visibility.',
            date: 'Nov 28, 2025',
          ),
          _buildUpdateCard(
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

  Widget _buildUpdateCard({
    required String version,
    required String title,
    required String description,
    required String date,
    bool isNew = false,
    bool isCritical = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCritical 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    version,
                    style: TextStyle(
                      color: isCritical ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isNew) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}