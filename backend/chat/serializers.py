# backend/chat/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import (
    User, Message, ChatRoom, RoomMembership, UserBlock, UserReport,
    Notification, UserSettings, Update, Tool, MessageRead
)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'avatar', 'bio', 'status_message',
            'online_status', 'last_seen', 'is_verified',
            'show_last_seen', 'show_read_receipts', 'show_profile_photo'
        ]
        read_only_fields = ['id', 'is_verified']

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'avatar', 'bio', 'phone_number',
            'date_of_birth', 'status_message', 'is_verified'
        ]
        read_only_fields = ['id', 'username', 'is_verified']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    
    class Meta:
        model = User
        fields = ['username', 'password']
    
    def validate_password(self, value):
        try:
            validate_password(value)
        except ValidationError as e:
            raise serializers.ValidationError(e.messages)
        return value
    
    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password']
        )
        UserSettings.objects.create(user=user)
        return user

class RoomMembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = RoomMembership
        fields = ['user', 'role', 'joined_at', 'is_muted']

class ChatRoomSerializer(serializers.ModelSerializer):
    members = RoomMembershipSerializer(source='roommembership_set', many=True, read_only=True)
    member_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = [
            'id', 'name', 'description', 'room_type', 'avatar',
            'is_private', 'max_members', 'created_at', 'members',
            'member_count', 'last_message'
        ]
    
    def get_member_count(self, obj):
        return obj.members.count()
    
    def get_last_message(self, obj):
        last_msg = obj.messages.filter(deleted_at__isnull=True).last()
        if last_msg:
            return MessageSerializer(last_msg).data
        return None

class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    reply_to = serializers.SerializerMethodField()
    read_by = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = [
            'id', 'sender', 'room', 'content', 'message_type',
            'file_url', 'file_size', 'thumbnail_url', 'reply_to',
            'timestamp', 'edited_at', 'reactions', 'read_by'
        ]
        read_only_fields = ['id', 'sender', 'timestamp']
    
    def get_reply_to(self, obj):
        if obj.reply_to:
            return {
                'id': obj.reply_to.id,
                'content': obj.reply_to.content[:50],
                'sender': obj.reply_to.sender.username
            }
        return None
    
    def get_read_by(self, obj):
        reads = MessageRead.objects.filter(message=obj).select_related('user')
        return [{'user': read.user.username, 'read_at': read.read_at} for read in reads]

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'body',
            'data', 'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

class UserSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSettings
        fields = [
            'push_notifications', 'message_notifications', 'group_notifications',
            'sound_enabled', 'vibration_enabled', 'auto_download_media',
            'backup_enabled', 'theme', 'language'
        ]

class UpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Update
        fields = [
            'id', 'title', 'description', 'version',
            'update_type', 'is_critical', 'release_date'
        ]

class ToolSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tool
        fields = ['id', 'name', 'description', 'icon', 'url', 'is_active']

class UserBlockSerializer(serializers.ModelSerializer):
    blocked_user = UserSerializer(source='blocked', read_only=True)
    
    class Meta:
        model = UserBlock
        fields = ['id', 'blocked_user', 'created_at']

class UserReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserReport
        fields = [
            'id', 'reported_user', 'report_type',
            'description', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']