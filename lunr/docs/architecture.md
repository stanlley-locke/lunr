# Lunr Flutter App Architecture

## Overview
Lunr is a Flutter-based chat application following a layered architecture.

## Folder Structure
- `lib/main.dart`: Entry point.
- `lib/models/`: Data models (User, ChatRoom, Message, etc.) with JSON serialization.
- `lib/screens/`: UI Screens (ChatList, ChatScreen, Settings, etc.).
- `lib/services/`: Business logic and external communication (API, Auth, Socket, Database).
- `lib/theme/`: App styling and theme definitions.

## State Management
- **Localized State**: Uses `StatefulWidget` and `setState` for simple UI state (e.g., loading flags, form inputs).
- **Global State**: Currently relies on Services (`AuthService`, `ApiService`) as singletons/providers of truth, often re-fetching data on screen init.
    - *Future Improvement*: Migrate to `Provider`, `Riverpod`, or `Bloc` for better reactive state management.

## Service Layer
### AuthService
Handles JWT token storage (`SharedPreferences`), login, registration, and user session management.

### ApiService
Wraps HTTP calls to the backend. Handles:
- Setting Authorization headers.
- Parsing JSON responses.
- Error handling (returns null or throws exceptions).
- Resolving relative image URLs (`getImageUrl`).

### SocketService
Manages real-time WebSocket connection (`socket_io_client`).
- Listens for `new_message` events.
- Emits `typing` events (planned).

### DatabaseService
Local persistence using `sqflite`.
- caches `ChatRooms` and `Messages` for offline access.
- Syncs with API on startup.

## Navigation
- Uses standard `Navigator.push` and `MaterialPageRoute`.
- `MainScreen` uses a custom Drawer navigation.
