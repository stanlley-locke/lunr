import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  Future<bool> register(String username, String password) async {
    final user = await ApiService().register(username, password);
    return user != null;
  }

  Future<bool> login(String username, String password) async {
    final response = await ApiService().login(username, password);
    if (response != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, response['access']);
      await prefs.setInt(_userIdKey, response['user']['id']);
      await prefs.setString(_usernameKey, response['user']['username']);
      return true;
    }
    return false;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}