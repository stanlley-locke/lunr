# Lunr API Reference

Base URL: `/api/`

## Authentication

### Register
`POST /auth/register/`
- **Body**: `{"username": "str", "password": "str"}`
- **Response**: `201 Created` with User object and tokens.

### Login
`POST /auth/login/`
- **Body**: `{"username": "str", "password": "str"}`
- **Response**: `200 OK` with `refresh` and `access` tokens.

### Refresh Token
`POST /auth/token/refresh/`
- **Body**: `{"refresh": "str"}`
- **Response**: `200 OK` with new `access` token.

## User Profile

### Get/Update Profile
`GET /users/profile/`
`PATCH /users/profile/`
- **Headers**: `Authorization: Bearer <token>`
- **Body (PATCH)**: `{"bio": "str", "avatar": "file/url", ...}`

### Search Users
`GET /users/search/?q=<query>`

## Chat Rooms

### List Rooms
`GET /rooms/`
- Returns all rooms the user is a member of.

### Create Room
`POST /rooms/`
- **Body**: `{"name": "str", "is_private": bool, "members": [user_ids]}`

### Room Details
`GET /rooms/<uuid:room_id>/`

### Archive/Unarchive Chat
`POST /rooms/<uuid:room_id>/archive/`
- Toggles the archive status for the requesting user.
- **Response**: `{"status": "success", "is_archived": bool}`

## Messages

### List Messages
`GET /rooms/<uuid:room_id>/messages/`

### Send Message
`POST /messages/`
- **Body**: `{"room": "uuid", "content": "str", "reply_to": "uuid" (optional)}`

### Add Reaction
`POST /messages/<uuid:message_id>/react/`
- **Body**: `{"reaction": "str"}` (e.g., "😊")

## Contacts

### List Contacts
`GET /contacts/`

### Add Contact
`POST /contacts/`
- **Body**: `{"username": "str", "alias": "str"}`

## Settings & Privacy

### Update Settings
`PUT /settings/`
- **Body**: `{"show_last_seen": bool, "show_read_receipts": bool, ...}`

### Block User
`POST /users/block/`
- **Body**: `{"username": "str"}`

## Backup & Restore

### Create Cloud Backup
`POST /cloud/backups/create/`

### List Backups
`GET /cloud/backups/`

### Restore Backup
`POST /cloud/backups/<uuid:backup_id>/restore/`
