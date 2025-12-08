import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lunr_chat.db');

    return await openDatabase(
      path,
      version: 4, // Bump version again to force upgrade check
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN sender_json TEXT');
          } catch (e) {
            print('Migration error (v2): $e');
          }
        }
        if (oldVersion < 3) {
           try {
            await db.execute('ALTER TABLE chat_rooms ADD COLUMN unread_count INTEGER DEFAULT 0');
          } catch (e) {
            print('Migration error (v3): $e');
          }
        }
        if (oldVersion < 4) {
           // Ensure unread_count exists even if v3 skipped
           try {
             // We can check if column exists or just try adding it again (sqlite gives error if exists)
             // or simpler: just catch the error if it already exists
            await db.execute('ALTER TABLE chat_rooms ADD COLUMN unread_count INTEGER DEFAULT 0');
           } catch (e) {
             print('Migration (v4) - unread_count likely exists: $e');
           }
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chat_rooms(
            id TEXT PRIMARY KEY,
            name TEXT,
            type TEXT,
            last_message_content TEXT,
            last_message_timestamp TEXT,
            participants TEXT,
            member_count INTEGER DEFAULT 0,
            unread_count INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            content TEXT,
            timestamp TEXT,
            sender_json TEXT, -- Store full user JSON for checking ID etc
            room_id TEXT
          )
        ''');
      },
    );
  }

  // --- Chat Rooms ---

  Future<void> insertChatRooms(List<ChatRoom> rooms) async {
    print('DEBUG: DatabaseService inserting ${rooms.length} chat rooms');
    try {
      final db = await database;
      final batch = db.batch();
      for (var room in rooms) {
        batch.insert(
          'chat_rooms',
          {
            'id': room.id,
            'name': room.name,
            'type': room.roomType,
            'last_message_content': room.lastMessage?.content,
            'last_message_timestamp': room.lastMessage?.timestamp.toIso8601String(),
            'participants': jsonEncode(room.members.map((m) => m.toJson()).toList()), // Store members as JSON
            'member_count': room.memberCount,
            'unread_count': room.unreadCount,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      print('DEBUG: DatabaseService inserted chat rooms successfully');
    } catch (e) {
      print('ERROR: DatabaseService insertChatRooms failed: $e');
    }
  }

  Future<List<ChatRoom>> getChatRooms() async {
    print('DEBUG: DatabaseService fetching chat rooms');
    final db = await database;
    final maps = await db.query('chat_rooms', orderBy: 'last_message_timestamp DESC');
    print('DEBUG: DatabaseService found ${maps.length} chat rooms');

    return List.generate(maps.length, (i) {
      // Basic safeguard for json decode
      List<RoomMembership> members = [];
      try {
        final membersJson = jsonDecode(maps[i]['participants'] as String) as List;
        members = membersJson.map((m) => RoomMembership.fromJson(m)).toList();
      } catch (e) {
        print('ERROR: Failed to parse participants for room ${maps[i]['id']}: $e');
      }

      return ChatRoom(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String? ?? '',
        roomType: maps[i]['type'] as String? ?? 'direct',
        members: members,
        memberCount: maps[i]['member_count'] as int? ?? members.length,
        unreadCount: maps[i]['unread_count'] as int? ?? 0,
        createdAt: DateTime.now(), // Placeholder as we didn't store it, or add col if needed
        lastMessage: maps[i]['last_message_content'] != null ? Message(
             id: 'temp_last_${maps[i]['id']}', 
             content: maps[i]['last_message_content'] as String, 
             sender: User(id: 0, username: 'User', onlineStatus: false), // Placeholder
             roomId: maps[i]['id'] as String, 
             timestamp: DateTime.tryParse(maps[i]['last_message_timestamp'] as String? ?? '') ?? DateTime.now()
        ) : null, 
      );
    });
  }

  // --- Messages ---

  Future<void> insertMessages(List<Message> messages) async {
    print('DEBUG: DatabaseService inserting ${messages.length} messages');
    try {
      final db = await database;
      // Using transaction for speed and safety
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (var message in messages) {
           batch.insert(
            'messages', 
            {
              'id': message.id,
              'content': message.content,
              'timestamp': message.timestamp.toIso8601String(),
              'sender_json': jsonEncode(message.sender.toJson()),
              'room_id': message.roomId, // Ensure this matches getMessages query
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      print('DEBUG: DatabaseService inserted messages successfully');
    } catch (e) {
      print('ERROR: DatabaseService insertMessages failed: $e');
    }
  }

  Future<List<Message>> getMessages(String roomId) async {
    print('DEBUG: DatabaseService fetching messages for room $roomId');
    try {
      final db = await database;
      final maps = await db.query(
        'messages',
        where: 'room_id = ?',
        whereArgs: [roomId],
        orderBy: 'timestamp ASC',
      );
      print('DEBUG: DatabaseService found ${maps.length} messages for room $roomId');

      return List.generate(maps.length, (i) {
        try {
          final senderJson = jsonDecode(maps[i]['sender_json'] as String);
          return Message(
            id: maps[i]['id'] as String,
            content: maps[i]['content'] as String,
            timestamp: DateTime.tryParse(maps[i]['timestamp'] as String? ?? '') ?? DateTime.now(),
            roomId: maps[i]['room_id'] as String,
            sender: User.fromJson(senderJson),
          );
        } catch (e) {
          print('ERROR: Failed to parse message ${maps[i]['id']}: $e');
          // Return a placeholder or skip? skipping is hard in List.generate.
          // valid approach: filter nulls later? 
          // For now return a dummy or rethrow? 
          // Let's return a dummy to avoid crash
           return Message(
            id: 'error_${i}',
            content: 'Error loading message',
            timestamp: DateTime.now(),
            roomId: roomId,
            sender: User(id: 0, username: 'Unknown', onlineStatus: false),
          );
        }
      });
    } catch (e) {
      print('ERROR: DatabaseService getMessages failed: $e');
      return [];
    }
  }

  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': message.id,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
        'sender_json': jsonEncode(message.sender.toJson()),
        'room_id': message.roomId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Also update last message in chat room
    await db.update(
      'chat_rooms',
      {
        'last_message_content': message.content,
        'last_message_timestamp': message.timestamp.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [message.roomId],
    );
  }

  Future<void> deleteChatRoom(String roomId) async {
    final db = await database;
    await db.delete(
      'chat_rooms',
      where: 'id = ?',
      whereArgs: [roomId],
    );
    // Also delete associated messages
    await db.delete(
      'messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }
}
