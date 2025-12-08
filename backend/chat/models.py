# backend/chat/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
import uuid

class User(AbstractUser):
    # Profile
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    phone_number = models.CharField(max_length=15, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    status_message = models.CharField(max_length=100, blank=True)
    is_verified = models.BooleanField(default=False)
    
    # Privacy Settings
    show_last_seen = models.BooleanField(default=True)
    show_read_receipts = models.BooleanField(default=True)
    show_profile_photo = models.BooleanField(default=True)
    show_status = models.BooleanField(default=True)
    
    # Activity
    online_status = models.BooleanField(default=False)
    last_seen = models.DateTimeField(null=True, blank=True)
    typing_status = models.JSONField(default=dict)
    device_tokens = models.JSONField(default=list)
    
    def __str__(self):
        return self.username

class ChatRoom(models.Model):
    ROOM_TYPES = [('direct', 'Direct'), ('group', 'Group')]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    room_type = models.CharField(max_length=10, choices=ROOM_TYPES, default='direct')
    avatar = models.ImageField(upload_to='room_avatars/', null=True, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_rooms')
    members = models.ManyToManyField(User, through='RoomMembership')
    is_private = models.BooleanField(default=False)
    max_members = models.IntegerField(default=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name or f"Room {self.id}"

class RoomMembership(models.Model):
    ROLES = [('admin', 'Admin'), ('member', 'Member')]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=ROLES, default='member')
    joined_at = models.DateTimeField(auto_now_add=True)
    is_muted = models.BooleanField(default=False)
    last_read_message = models.ForeignKey('Message', null=True, blank=True, on_delete=models.SET_NULL)
    
    class Meta:
        unique_together = ['user', 'room']

class Message(models.Model):
    MESSAGE_TYPES = [
        ('text', 'Text'), ('image', 'Image'), ('video', 'Video'),
        ('audio', 'Audio'), ('file', 'File'), ('location', 'Location'),
        ('contact', 'Contact'), ('sticker', 'Sticker')
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sender = models.ForeignKey(User, related_name='sent_messages', on_delete=models.CASCADE)
    room = models.ForeignKey(ChatRoom, related_name='messages', on_delete=models.CASCADE)
    content = models.TextField()
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='text')
    
    # Media fields
    file_url = models.URLField(blank=True)
    file_size = models.BigIntegerField(null=True)
    thumbnail_url = models.URLField(blank=True)
    
    # Message features
    reply_to = models.ForeignKey('self', null=True, blank=True, on_delete=models.CASCADE, related_name='replies')
    forwarded_from = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL, related_name='forwards')
    
    # Timestamps
    timestamp = models.DateTimeField(auto_now_add=True)
    edited_at = models.DateTimeField(null=True, blank=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    
    # Reactions
    reactions = models.JSONField(default=dict)
    
    class Meta:
        ordering = ['timestamp']
        indexes = [
            models.Index(fields=['room', 'timestamp']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.sender} in {self.room}: {self.content[:20]}"

class MessageRead(models.Model):
    message = models.ForeignKey(Message, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    read_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['message', 'user']

class UserBlock(models.Model):
    blocker = models.ForeignKey(User, related_name='blocked_users', on_delete=models.CASCADE)
    blocked = models.ForeignKey(User, related_name='blocked_by', on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['blocker', 'blocked']

class UserReport(models.Model):
    REPORT_TYPES = [
        ('spam', 'Spam'), ('harassment', 'Harassment'),
        ('inappropriate', 'Inappropriate Content'), ('other', 'Other')
    ]
    
    reporter = models.ForeignKey(User, related_name='reports_made', on_delete=models.CASCADE)
    reported_user = models.ForeignKey(User, related_name='reports_received', on_delete=models.CASCADE)
    report_type = models.CharField(max_length=20, choices=REPORT_TYPES)
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_resolved = models.BooleanField(default=False)

class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('message', 'New Message'), ('group_invite', 'Group Invite'),
        ('friend_request', 'Friend Request'), ('system', 'System')
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=100)
    body = models.TextField()
    data = models.JSONField(default=dict)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']

class UserSettings(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    
    # Notification settings
    push_notifications = models.BooleanField(default=True)
    message_notifications = models.BooleanField(default=True)
    group_notifications = models.BooleanField(default=True)
    sound_enabled = models.BooleanField(default=True)
    vibration_enabled = models.BooleanField(default=True)
    
    # Chat settings
    auto_download_media = models.BooleanField(default=True)
    backup_enabled = models.BooleanField(default=False)
    
    # App settings
    theme = models.CharField(max_length=10, choices=[('light', 'Light'), ('dark', 'Dark')], default='light')
    language = models.CharField(max_length=10, default='en')
    
    def __str__(self):
        return f"Settings for {self.user.username}"

class Update(models.Model):
    UPDATE_TYPES = [('feature', 'Feature'), ('bug_fix', 'Bug Fix'), ('security', 'Security')]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    version = models.CharField(max_length=20)
    update_type = models.CharField(max_length=20, choices=UPDATE_TYPES)
    is_critical = models.BooleanField(default=False)
    release_date = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-release_date']

class Tool(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=50)
    url = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name

class Contact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='contacts')
    contact_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_by')
    alias = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
from django.db import models
from django.utils import timezone
import uuid

class User(AbstractUser):
    # Profile
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    bio = models.TextField(max_length=500, blank=True)
    phone_number = models.CharField(max_length=15, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    status_message = models.CharField(max_length=100, blank=True)
    is_verified = models.BooleanField(default=False)
    
    # Privacy Settings
    show_last_seen = models.BooleanField(default=True)
    show_read_receipts = models.BooleanField(default=True)
    show_profile_photo = models.BooleanField(default=True)
    show_status = models.BooleanField(default=True)
    
    # Activity
    online_status = models.BooleanField(default=False)
    last_seen = models.DateTimeField(null=True, blank=True)
    typing_status = models.JSONField(default=dict)
    device_tokens = models.JSONField(default=list)
    
    def __str__(self):
        return self.username

class ChatRoom(models.Model):
    ROOM_TYPES = [('direct', 'Direct'), ('group', 'Group')]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    room_type = models.CharField(max_length=10, choices=ROOM_TYPES, default='direct')
    avatar = models.ImageField(upload_to='room_avatars/', null=True, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_rooms')
    members = models.ManyToManyField(User, through='RoomMembership')
    is_private = models.BooleanField(default=False)
    max_members = models.IntegerField(default=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.name or f"Room {self.id}"

class RoomMembership(models.Model):
    ROLES = [('admin', 'Admin'), ('member', 'Member')]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE)
    role = models.CharField(max_length=10, choices=ROLES, default='member')
    joined_at = models.DateTimeField(auto_now_add=True)
    is_muted = models.BooleanField(default=False)
    last_read_message = models.ForeignKey('Message', null=True, blank=True, on_delete=models.SET_NULL)
    
    class Meta:
        unique_together = ['user', 'room']

class Message(models.Model):
    MESSAGE_TYPES = [
        ('text', 'Text'), ('image', 'Image'), ('video', 'Video'),
        ('audio', 'Audio'), ('file', 'File'), ('location', 'Location'),
        ('contact', 'Contact'), ('sticker', 'Sticker')
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sender = models.ForeignKey(User, related_name='sent_messages', on_delete=models.CASCADE)
    room = models.ForeignKey(ChatRoom, related_name='messages', on_delete=models.CASCADE)
    content = models.TextField()
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='text')
    
    # Media fields
    file_url = models.URLField(blank=True)
    file_size = models.BigIntegerField(null=True)
    thumbnail_url = models.URLField(blank=True)
    
    # Message features
    reply_to = models.ForeignKey('self', null=True, blank=True, on_delete=models.CASCADE, related_name='replies')
    forwarded_from = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL, related_name='forwards')
    
    # Timestamps
    timestamp = models.DateTimeField(auto_now_add=True)
    edited_at = models.DateTimeField(null=True, blank=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    
    # Reactions
    reactions = models.JSONField(default=dict)
    
    class Meta:
        ordering = ['timestamp']
        indexes = [
            models.Index(fields=['room', 'timestamp']),
            models.Index(fields=['sender']),
        ]
    
    def __str__(self):
        return f"{self.sender} in {self.room}: {self.content[:20]}"

class MessageRead(models.Model):
    message = models.ForeignKey(Message, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    read_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['message', 'user']

class UserBlock(models.Model):
    blocker = models.ForeignKey(User, related_name='blocked_users', on_delete=models.CASCADE)
    blocked = models.ForeignKey(User, related_name='blocked_by', on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['blocker', 'blocked']

class UserReport(models.Model):
    REPORT_TYPES = [
        ('spam', 'Spam'), ('harassment', 'Harassment'),
        ('inappropriate', 'Inappropriate Content'), ('other', 'Other')
    ]
    
    reporter = models.ForeignKey(User, related_name='reports_made', on_delete=models.CASCADE)
    reported_user = models.ForeignKey(User, related_name='reports_received', on_delete=models.CASCADE)
    report_type = models.CharField(max_length=20, choices=REPORT_TYPES)
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_resolved = models.BooleanField(default=False)

class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('message', 'New Message'), ('group_invite', 'Group Invite'),
        ('friend_request', 'Friend Request'), ('system', 'System')
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=100)
    body = models.TextField()
    data = models.JSONField(default=dict)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']

class UserSettings(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    
    # Notification settings
    push_notifications = models.BooleanField(default=True)
    message_notifications = models.BooleanField(default=True)
    group_notifications = models.BooleanField(default=True)
    sound_enabled = models.BooleanField(default=True)
    vibration_enabled = models.BooleanField(default=True)
    
    # Chat settings
    auto_download_media = models.BooleanField(default=True)
    backup_enabled = models.BooleanField(default=False)
    
    # App settings
    theme = models.CharField(max_length=10, choices=[('light', 'Light'), ('dark', 'Dark')], default='light')
    language = models.CharField(max_length=10, default='en')
    
    def __str__(self):
        return f"Settings for {self.user.username}"

class Update(models.Model):
    UPDATE_TYPES = [('feature', 'Feature'), ('bug_fix', 'Bug Fix'), ('security', 'Security')]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    version = models.CharField(max_length=20)
    update_type = models.CharField(max_length=20, choices=UPDATE_TYPES)
    is_critical = models.BooleanField(default=False)
    release_date = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-release_date']

class Tool(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=50)
    url = models.URLField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.name

class Contact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='contacts')
    contact_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_by')
    alias = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'contact_user']
        ordering = ['alias', 'contact_user__username']
    
    
    def __str__(self):
        return f"{self.user.username} -> {self.alias or self.contact_user.username}"

class Media(models.Model):
    MEDIA_TYPES = [('image', 'Image'), ('video', 'Video'), ('audio', 'Audio'), ('file', 'File')]
    
    file = models.FileField(upload_to='uploads/')
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_media')
    media_type = models.CharField(max_length=10, choices=MEDIA_TYPES, default='file')
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.media_type} by {self.uploaded_by.username} at {self.created_at}"