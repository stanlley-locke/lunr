from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    User, ChatRoom, RoomMembership, Message, MessageRead,
    UserBlock, UserReport, Notification, UserSettings,
    Update, Tool
)

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'email', 'online_status', 'last_seen', 'is_verified']
    list_filter = ['online_status', 'is_verified', 'date_joined']
    search_fields = ['username', 'email']
    
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Profile', {
            'fields': ('avatar', 'bio', 'phone_number', 'date_of_birth', 'status_message', 'is_verified')
        }),
        ('Privacy', {
            'fields': ('show_last_seen', 'show_read_receipts', 'show_profile_photo', 'show_status')
        }),
        ('Activity', {
            'fields': ('online_status', 'last_seen', 'device_tokens')
        }),
    )

class RoomMembershipInline(admin.TabularInline):
    model = RoomMembership
    extra = 0

@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ['name', 'room_type', 'created_by', 'member_count', 'created_at']
    list_filter = ['room_type', 'is_private', 'created_at']
    search_fields = ['name', 'description']
    inlines = [RoomMembershipInline]
    
    def member_count(self, obj):
        return obj.members.count()
    member_count.short_description = 'Members'

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['sender', 'room', 'message_type', 'content_preview', 'timestamp']
    list_filter = ['message_type', 'timestamp', 'edited_at']
    search_fields = ['content', 'sender__username']
    
    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'

@admin.register(UserBlock)
class UserBlockAdmin(admin.ModelAdmin):
    list_display = ['blocker', 'blocked', 'created_at']
    list_filter = ['created_at']
    search_fields = ['blocker__username', 'blocked__username']

@admin.register(UserReport)
class UserReportAdmin(admin.ModelAdmin):
    list_display = ['reporter', 'reported_user', 'report_type', 'is_resolved', 'created_at']
    list_filter = ['report_type', 'is_resolved', 'created_at']
    search_fields = ['reporter__username', 'reported_user__username']
    actions = ['mark_resolved']
    
    def mark_resolved(self, request, queryset):
        queryset.update(is_resolved=True)
    mark_resolved.short_description = 'Mark selected reports as resolved'

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_type', 'title', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['user__username', 'title']

@admin.register(UserSettings)
class UserSettingsAdmin(admin.ModelAdmin):
    list_display = ['user', 'push_notifications', 'theme', 'language']
    list_filter = ['push_notifications', 'theme', 'language']
    search_fields = ['user__username']

@admin.register(Update)
class UpdateAdmin(admin.ModelAdmin):
    list_display = ['title', 'version', 'update_type', 'is_critical', 'release_date']
    list_filter = ['update_type', 'is_critical', 'release_date']
    search_fields = ['title', 'version']

@admin.register(Tool)
class ToolAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'description']
