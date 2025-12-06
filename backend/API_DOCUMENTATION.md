# Lunr Chat API Documentation

## Base URL
```
https://your-domain.com/api/
```

## Authentication
All authenticated endpoints require JWT token in header:
```
Authorization: Bearer <access_token>
```

## Endpoints

### Authentication

#### Register
- **POST** `/auth/register/`
- **Body**: `{"username": "string", "password": "string"}`
- **Response**: `{"user": {...}, "message": "Welcome to Lunr!"}`

#### Login
- **POST** `/auth/login/`
- **Body**: `{"username": "string", "password": "string"}`
- **Response**: `{"refresh": "token", "access": "token", "user": {...}}`

#### Logout
- **POST** `/auth/logout/`
- **Headers**: Authorization required
- **Response**: `{"message": "Logged out successfully"}`

### User Profile

#### Get/Update Profile
- **GET/PUT** `/profile/`
- **Headers**: Authorization required
- **PUT Body**: `{"bio": "string", "status_message": "string", ...}`
- **Response**: User profile data

#### Search Users
- **GET** `/users/search/?q=query`
- **Headers**: Authorization required
- **Response**: Array of users matching query

### Chat Rooms

#### List/Create Rooms
- **GET/POST** `/rooms/`
- **Headers**: Authorization required
- **POST Body**: 
  - Direct: `{"room_type": "direct", "other_user_id": 123}`
  - Group: `{"room_type": "group", "name": "string", "description": "string"}`
- **Response**: Array of rooms or created room

#### Room Details
- **GET/PUT/DELETE** `/rooms/{room_id}/`
- **Headers**: Authorization required
- **PUT Body**: `{"name": "string", "description": "string"}` (Admin only)
- **Response**: Room details or success message

#### Room Messages
- **GET** `/rooms/{room_id}/messages/`
- **Headers**: Authorization required
- **Response**: Array of messages in room

### Messages

#### Send Message
- **POST** `/messages/`
- **Headers**: Authorization required
- **Body**: `{"room_id": "uuid", "content": "string", "message_type": "text", "reply_to": "uuid"}`
- **Response**: Created message

#### Edit/Delete Message
- **PUT/DELETE** `/messages/{message_id}/`
- **Headers**: Authorization required
- **PUT Body**: `{"content": "string"}`
- **Response**: Updated message or success message

#### Add Reaction
- **POST** `/messages/{message_id}/react/`
- **Headers**: Authorization required
- **Body**: `{"emoji": "👍"}`
- **Response**: `{"reactions": {...}}`

### Settings

#### Get/Update Settings
- **GET/PUT** `/settings/`
- **Headers**: Authorization required
- **PUT Body**: `{"push_notifications": true, "theme": "dark", ...}`
- **Response**: User settings

### Privacy

#### Block User
- **POST** `/privacy/block/`
- **Headers**: Authorization required
- **Body**: `{"user_id": 123}`
- **Response**: Success message

#### Unblock User
- **DELETE** `/privacy/unblock/{user_id}/`
- **Headers**: Authorization required
- **Response**: Success message

#### List Blocked Users
- **GET** `/privacy/blocked/`
- **Headers**: Authorization required
- **Response**: Array of blocked users

### Notifications

#### List Notifications
- **GET** `/notifications/`
- **Headers**: Authorization required
- **Response**: Array of notifications

#### Mark as Read
- **PUT** `/notifications/{notification_id}/read/`
- **Headers**: Authorization required
- **Response**: Success message

### App Features

#### Get Updates
- **GET** `/updates/`
- **Headers**: Authorization required
- **Response**: Array of app updates

#### Get Tools
- **GET** `/tools/`
- **Headers**: Authorization required
- **Response**: Array of available tools

#### Report User
- **POST** `/report/`
- **Headers**: Authorization required
- **Body**: `{"reported_user": 123, "report_type": "spam", "description": "string"}`
- **Response**: Success message

## WebSocket Connection

### Chat WebSocket
- **URL**: `ws://your-domain.com/ws/chat/{room_id}/`
- **Authentication**: JWT token in query params or headers

#### Message Types

##### Send Message
```json
{
  "type": "message",
  "content": "Hello world",
  "message_type": "text",
  "reply_to": "message_uuid"
}
```

##### Typing Indicator
```json
{
  "type": "typing",
  "is_typing": true
}
```

##### Read Receipt
```json
{
  "type": "read_receipt",
  "message_id": "message_uuid"
}
```

#### Received Events

##### New Message
```json
{
  "type": "message",
  "message_id": "uuid",
  "content": "Hello world",
  "sender_id": 123,
  "sender_username": "john",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

##### Typing Status
```json
{
  "type": "typing",
  "user_id": 123,
  "username": "john",
  "is_typing": true
}
```

##### User Status
```json
{
  "type": "user_status",
  "user_id": 123,
  "username": "john",
  "status": "online"
}
```

## Error Responses

All error responses follow this format:
```json
{
  "error": "Error message",
  "details": {...}
}
```

Common HTTP status codes:
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Rate Limiting

- Anonymous users: 100 requests/day
- Authenticated users: 1000 requests/day
- WebSocket connections: No limit

## File Uploads

### Avatar Upload
- **POST** `/profile/` with `multipart/form-data`
- **Field**: `avatar`
- **Max size**: 10MB
- **Formats**: JPG, PNG, GIF

### Message Files
- **POST** `/messages/` with `multipart/form-data`
- **Fields**: `file`, `thumbnail` (optional)
- **Max size**: 10MB per file
- **Formats**: Images, videos, documents