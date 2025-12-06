import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  // Use your Codespace URL
  static const String _baseUrl = 'https://humble-sniffle-wr46p9pq554crp5-8000.app.github.dev/api';

  Future<User?> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> getConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMessages(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/$userId/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage(String token, int receiverId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'receiver_id': receiverId,
          'content': content
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}