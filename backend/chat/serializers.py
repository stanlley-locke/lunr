# backend/chat/serializers.py
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from .models import (
    User, Message, ChatRoom, RoomMembership, UserBlock, UserReport,
    Notification, UserSettings, Update, Tool, MessageRead, Contact, Media
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
            'id', 'username', 'email', 'avatar', 'bio', 'phone_number',
            'date_of_birth', 'status_message', 'is_verified',
            'show_last_seen', 'show_read_receipts', 'show_profile_photo', 'show_status'
        ]
        read_only_fields = ['id', 'username', 'is_verified']

    # Explicitly define avatar as CharField to allow updating with a URL string
    avatar = serializers.CharField(required=False, allow_null=True)

    def update(self, instance, validated_data):
        avatar = validated_data.pop('avatar', None)
        
        # Update other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
            
        # Handle avatar
        if avatar is not None:
             # If it's a URL string from our own media endpoint, we might want to store the relative path
             # or just the Full URL if the field allows it.
             # User.avatar is an ImageField.
             # Django ImageField stores the path relative to MEDIA_ROOT.
             # If we receive "http://.../media/uploads/file.jpg", we want "uploads/file.jpg"
             
             # Simple logic: if it contains '/media/', strip it.
             if '/media/' in avatar:
                 instance.avatar = avatar.split('/media/')[-1]
             else:
                 instance.avatar = avatar
        
        instance.save()
        return instance

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        # Manually construct absolute URL for avatar if it exists
        if instance.avatar:
            request = self.context.get('request')
            if request:
                ret['avatar'] = request.build_absolute_uri(instance.avatar.url)
        return ret

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True)

    def validate_new_password(self, value):
        validate_password(value)
        return value

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
        fields = ['user', 'role', 'joined_at', 'is_muted', 'is_archived']

class ChatRoomSerializer(serializers.ModelSerializer):
    members = RoomMembershipSerializer(source='roommembership_set', many=True, read_only=True)
    member_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatRoom
        fields = [
            'id', 'name', 'description', 'room_type', 'avatar',
            'is_private', 'max_members', 'created_at', 'members',
            'member_count', 'last_message', 'unread_count'
        ]
    
    def get_member_count(self, obj):
        return obj.members.count()

    def get_unread_count(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            # Count messages in this room that are NOT read by this user AND NOT sent by this user
            return obj.messages.exclude(sender=user).exclude(messageread__user=user).count()
        return 0
    
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
            'data', 'is_read', 'created_at']
        read_only_fields = ['id', 'created_at']

class MediaSerializer(serializers.ModelSerializer):
    uploaded_by = UserSerializer(read_only=True)
    
    class Meta:
        model = Media
        fields = ['id', 'file', 'uploaded_by', 'media_type', 'created_at']

class ContactSerializer(serializers.ModelSerializer):
    contact_user = UserSerializer(read_only=True)
    
    class Meta:
        model = Contact
        fields = ['id', 'contact_user', 'alias', 'created_at']

class UserSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSettings
        fields = [
            'push_notifications', 'message_notifications', 'group_notifications',
            'sound_enabled', 'vibration_enabled', 'auto_download_media',
            'media_visibility', 'wallpaper', 'font_size',
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