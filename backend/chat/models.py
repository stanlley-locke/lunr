# backend/chat/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    online_status = models.BooleanField(default=False)
    last_seen = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return self.username

class Message(models.Model):
    sender = models.ForeignKey(User, related_name='sent_messages', on_delete=models.CASCADE)
    receiver = models.ForeignKey(User, related_name='received_messages', on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['timestamp']
        indexes = [
            models.Index(fields=['sender', 'receiver']),
            models.Index(fields=['timestamp']),
        ]
    
    def __str__(self):
        return f"{self.sender} → {self.receiver}: {self.content[:20]}"