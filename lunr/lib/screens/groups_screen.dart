import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final List<Map<String, dynamic>> _groups = [
    {
      'name': 'Flutter Developers',
      'members': 24,
      'lastMessage': 'John: Check out this new package!',
      'time': '2:30 PM',
      'unread': 3,
    },
    {
      'name': 'Design Team',
      'members': 8,
      'lastMessage': 'Sarah: New mockups are ready',
      'time': '1:15 PM',
      'unread': 0,
    },
    {
      'name': 'Project Alpha',
      'members': 12,
      'lastMessage': 'Mike: Meeting at 3 PM',
      'time': '11:45 AM',
      'unread': 1,
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
              'assets/icons/lunr_group_icon.png',
              width: 24,
              height: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Groups',
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: themeProvider.textColor,
            ),
            onPressed: () {
              _showCreateGroupDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeProvider.searchBarColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: themeProvider.subtitleColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search groups...',
                    style: TextStyle(
                      color: themeProvider.subtitleColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Groups List
          Expanded(
            child: _groups.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return _buildGroupTile(group);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF2196F3),
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          _showCreateGroupDialog();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/lunr_group_icon.png',
              width: 80,
              height: 80,
              color: themeProvider.subtitleColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Groups Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create or join groups to start chatting',
            style: TextStyle(
              color: themeProvider.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/icons/lunr_group_icon.png',
            width: 24,
            height: 24,
            color: Colors.white,
          ),
        ),
        title: Text(
          group['name'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${group['members']} members',
              style: TextStyle(
                color: themeProvider.subtitleColor,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 2),
            Text(
              group['lastMessage'],
              style: TextStyle(
                color: themeProvider.subtitleColor,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              group['time'],
              style: TextStyle(
                color: themeProvider.subtitleColor,
                fontSize: 12,
              ),
            ),
            if (group['unread'] > 0) ...[
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2196F3).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${group['unread']}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          // Navigate to group chat
        },
      ),
    );
  }

  void _showCreateGroupDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeProvider.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create Group',
            style: TextStyle(color: themeProvider.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: TextStyle(color: themeProvider.textColor),
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(color: themeProvider.subtitleColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                style: TextStyle(color: themeProvider.textColor),
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: TextStyle(color: themeProvider.subtitleColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF2196F3)),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: themeProvider.subtitleColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Create group logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }
}