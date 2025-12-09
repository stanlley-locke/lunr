# backend/chat/urls.py
from django.urls import path
from .views import (
    # Authentication
    register, login, logout, change_password, delete_account,
    
    # User Profile
    user_profile, search_users,
    
    
    # Chat Rooms
    chat_rooms, chat_room_detail, room_messages, mark_room_read,
    room_members, room_member_detail,
    
    # Contacts
    contacts, contact_detail,
    
    # Messages
    send_message, message_detail, add_reaction,
    
    # Settings & Privacy
    user_settings, block_user, unblock_user, blocked_users,
    
    # Notifications
    notifications, mark_notification_read,
    
    # App Features
    updates, tools, report_user,
    
    # Media
    FileUploadView,
    
    # Archive & Backup
    archive_chat, unarchive_chat, backup_data
)

urlpatterns = [
    # Authentication
    path('auth/register/', register, name='register'),
    path('auth/login/', login, name='login'),
    path('auth/logout/', logout, name='logout'),
    path('auth/change-password/', change_password, name='change_password'),
    path('auth/delete/', delete_account, name='delete_account'),
    
    # User Profile
    path('profile/', user_profile, name='user_profile'),
    path('users/search/', search_users, name='search_users'),
    
    # Chat Rooms
    path('rooms/', chat_rooms, name='chat_rooms'),
    path('rooms/<uuid:room_id>/', chat_room_detail, name='chat_room_detail'),
    path('rooms/<uuid:room_id>/', chat_room_detail, name='chat_room_detail'),
    path('rooms/<uuid:room_id>/messages/', room_messages, name='room_messages'),
    path('rooms/<uuid:room_id>/read/', mark_room_read, name='mark_room_read'),
    path('rooms/<uuid:room_id>/members/', room_members, name='room_members'),
    path('rooms/<uuid:room_id>/members/<int:user_id>/', room_member_detail, name='room_member_detail'),
    
    # Contacts
    path('contacts/', contacts, name='contacts'),
    path('contacts/<int:contact_id>/', contact_detail, name='contact_detail'),
    
    # Messages
    path('messages/', send_message, name='send_message'),
    path('messages/<uuid:message_id>/', message_detail, name='message_detail'),
    path('messages/<uuid:message_id>/react/', add_reaction, name='add_reaction'),
    
    # Settings & Privacy
    path('settings/', user_settings, name='user_settings'),
    path('privacy/block/', block_user, name='block_user'),
    path('privacy/unblock/<int:user_id>/', unblock_user, name='unblock_user'),
    path('privacy/blocked/', blocked_users, name='blocked_users'),
    
    # Notifications
    path('notifications/', notifications, name='notifications'),
    path('notifications/<int:notification_id>/read/', mark_notification_read, name='mark_notification_read'),
    
    # App Features
    path('updates/', updates, name='updates'),
    path('tools/', tools, name='tools'),
    path('report/', report_user, name='report_user'),
    
    # Media
    path('upload/', FileUploadView.as_view(), name='file_upload'),
    
    # Archive & Backup
    path('rooms/<uuid:room_id>/archive/', archive_chat, name='archive_chat'),
    path('rooms/<uuid:room_id>/unarchive/', unarchive_chat, name='unarchive_chat'),
    path('backup/', backup_data, name='backup_data'),
]