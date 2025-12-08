import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user_settings.dart';

class ApiService {
  static const String _baseUrl = 'https://humble-sniffle-wr46p9pq554crp5-8000.app.github.dev/api';

  // Authentication
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

  Future<bool> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/logout/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Profile
  Future<User?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> updateProfile(String token, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> searchUsers(String token, String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/search/?q=$query'),
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

  // Chat Rooms
  Future<List<ChatRoom>> getChatRooms(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/rooms/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatRoom.fromJson(json)).toList();
    }
    throw Exception('Failed to load chat rooms: ${response.statusCode}');
  }

  Future<ChatRoom?> createChatRoom(String token, Map<String, dynamic> data) async {
    try {
      print('Creating room with data: ${jsonEncode(data)}');
      final response = await http.post(
        Uri.parse('$_baseUrl/rooms/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(data),
      );
      
      print('Room creation response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        return ChatRoom.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Room creation error: $e');
      return null;
    }
  }

  Future<bool> deleteChatRoom(String token, String roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/rooms/$roomId/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Messages
  Future<List<Message>> getRoomMessages(String token, String roomId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/rooms/$roomId/messages/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    }
    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  Future<Message?> sendMessage(String token, String roomId, String content, {String? replyTo}) async {
    try {
      final data = {
        'room_id': roomId,
        'content': content,
        'message_type': 'text',
      };
      if (replyTo != null) data['reply_to'] = replyTo;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201) {
        return Message.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteMessage(String token, String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/messages/$messageId/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addReaction(String token, String messageId, String emoji) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/$messageId/react/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'emoji': emoji}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Settings
  Future<UserSettings?> getSettings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/settings/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return UserSettings.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserSettings?> updateSettings(String token, UserSettings settings) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/settings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(settings.toJson()),
      );
      
      if (response.statusCode == 200) {
        return UserSettings.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Privacy
  Future<bool> blockUser(String token, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/privacy/block/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // App Features
  Future<List<dynamic>> getUpdates(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/updates/'),
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

  Future<List<dynamic>> getTools(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tools/'),
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
}