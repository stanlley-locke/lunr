import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(LunrApp());
}

// void main() {
//   runApp(LunrApp());
// }

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
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Lunr',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: _isAuthenticated == null
                ? Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF2196F3).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icons/lunr_app_icon.png',
                              width: 60,
                              height: 60,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  )
                : _isAuthenticated!
                    ? MainScreen()
                    : LoginScreen(),
          );
        },
      ),
    );
  }
}
