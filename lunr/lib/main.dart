import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/chat_list_screen.dart';

void main() {
  runApp(LunrApp());
}

class LunrApp extends StatefulWidget {
  @override
  _LunrAppState createState() => _LunrAppState();
}

class _LunrAppState extends State<LunrApp> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await AuthService().getToken();
    setState(() {
      _isAuthenticated = token != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lunr',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _isAuthenticated == null
          ? Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isAuthenticated!
              ? ChatListScreen()
              : LoginScreen(),
    );
  }
}