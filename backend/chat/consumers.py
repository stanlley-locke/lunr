# backend/chat/consumers.py
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from .models import Message, User

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        if self.user.is_anonymous:
            await self.close()
            return
        
        self.other_user_id = self.scope['url_route']['kwargs']['user_id']
        self.room_group_name = f"lunr_{min(self.user.id, self.other_user_id)}_{max(self.user.id, self.other_user_id)}"
        
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        
        # Update online status
        await self.set_online_status(True)

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )
        # Update online status
        await self.set_online_status(False)

    async def receive(self, text_data):
        data = json.loads(text_data)
        message_content = data['message']
        
        # Save message
        message = await self.save_message(self.user.id, self.other_user_id, message_content)
        
        # Send to group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': message_content,
                'sender_id': self.user.id,
                'timestamp': message.timestamp.isoformat()
            }
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'message': event['message'],
            'sender_id': event['sender_id'],
            'timestamp': event['timestamp']
        }))

    @database_sync_to_async
    def save_message(self, sender_id, receiver_id, content):
        sender = User.objects.get(id=sender_id)
        receiver = User.objects.get(id=receiver_id)
        return Message.objects.create(sender=sender, receiver=receiver, content=content)

    @database_sync_to_async
    def set_online_status(self, status):
        user = User.objects.get(id=self.user.id)
        user.online_status = status
        if not status:
            user.last_seen = timezone.now()
        user.save()