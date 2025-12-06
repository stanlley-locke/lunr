# backend/chat/consumers.py
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from .models import Message, User, ChatRoom, RoomMembership, MessageRead

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return
        
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f"chat_{self.room_id}"
        
        # Check if user is member of the room
        is_member = await self.check_room_membership()
        if not is_member:
            await self.close()
            return
        
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        
        # Update online status
        await self.set_online_status(True)
        
        # Notify others user joined
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_status',
                'user_id': self.user.id,
                'username': self.user.username,
                'status': 'online'
            }
        )

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        
        # Update online status
        await self.set_online_status(False)
        
        # Notify others user left
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_status',
                'user_id': self.user.id,
                'username': self.user.username,
                'status': 'offline'
            }
        )

    async def receive(self, text_data):
        data = json.loads(text_data)
        message_type = data.get('type', 'message')
        
        if message_type == 'message':
            await self.handle_message(data)
        elif message_type == 'typing':
            await self.handle_typing(data)
        elif message_type == 'read_receipt':
            await self.handle_read_receipt(data)

    async def handle_message(self, data):
        content = data.get('content')
        msg_type = data.get('message_type', 'text')
        reply_to_id = data.get('reply_to')
        
        if not content:
            return
        
        # Save message
        message = await self.save_message(content, msg_type, reply_to_id)
        
        # Send to group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message_id': str(message.id),
                'content': content,
                'message_type': msg_type,
                'sender_id': self.user.id,
                'sender_username': self.user.username,
                'timestamp': message.timestamp.isoformat(),
                'reply_to': reply_to_id
            }
        )

    async def handle_typing(self, data):
        is_typing = data.get('is_typing', False)
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator',
                'user_id': self.user.id,
                'username': self.user.username,
                'is_typing': is_typing
            }
        )

    async def handle_read_receipt(self, data):
        message_id = data.get('message_id')
        if message_id:
            await self.mark_message_read(message_id)

    async def chat_message(self, event):
        # Don't send message back to sender
        if event['sender_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'message',
                'message_id': event['message_id'],
                'content': event['content'],
                'message_type': event['message_type'],
                'sender_id': event['sender_id'],
                'sender_username': event['sender_username'],
                'timestamp': event['timestamp'],
                'reply_to': event.get('reply_to')
            }))

    async def typing_indicator(self, event):
        # Don't send typing indicator back to sender
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'typing',
                'user_id': event['user_id'],
                'username': event['username'],
                'is_typing': event['is_typing']
            }))

    async def user_status(self, event):
        # Don't send status back to sender
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'user_status',
                'user_id': event['user_id'],
                'username': event['username'],
                'status': event['status']
            }))

    @database_sync_to_async
    def check_room_membership(self):
        try:
            RoomMembership.objects.get(user=self.user, room_id=self.room_id)
            return True
        except RoomMembership.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content, msg_type, reply_to_id):
        room = ChatRoom.objects.get(id=self.room_id)
        
        message_data = {
            'sender': self.user,
            'room': room,
            'content': content,
            'message_type': msg_type
        }
        
        if reply_to_id:
            try:
                reply_message = Message.objects.get(id=reply_to_id, room=room)
                message_data['reply_to'] = reply_message
            except Message.DoesNotExist:
                pass
        
        message = Message.objects.create(**message_data)
        
        # Update room timestamp
        room.updated_at = timezone.now()
        room.save()
        
        return message

    @database_sync_to_async
    def mark_message_read(self, message_id):
        try:
            message = Message.objects.get(id=message_id, room_id=self.room_id)
            MessageRead.objects.get_or_create(message=message, user=self.user)
        except Message.DoesNotExist:
            pass

    @database_sync_to_async
    def set_online_status(self, status):
        user = User.objects.get(id=self.user.id)
        user.online_status = status
        if not status:
            user.last_seen = timezone.now()
        user.save()