# backend/chat/urls.py
from django.urls import path
from .views import (
    # Authentication
    register, login, logout,
    
    # User Profile
    user_profile, search_users,
    
    # Chat Rooms
    # Chat Rooms
    chat_rooms, chat_room_detail, room_messages, mark_room_read,
    
    # Messages
    send_message, message_detail, add_reaction,
    
    # Settings & Privacy
    user_settings, block_user, unblock_user, blocked_users,
    
    # Notifications
    notifications, mark_notification_read,
    
    # App Features
    updates, tools, report_user
)

urlpatterns = [
    # Authentication
    path('auth/register/', register, name='register'),
    path('auth/login/', login, name='login'),
    path('auth/logout/', logout, name='logout'),
    
    # User Profile
    path('profile/', user_profile, name='user_profile'),
    path('users/search/', search_users, name='search_users'),
    
    # Chat Rooms
    path('rooms/', chat_rooms, name='chat_rooms'),
    path('rooms/<uuid:room_id>/', chat_room_detail, name='chat_room_detail'),
    path('rooms/<uuid:room_id>/', chat_room_detail, name='chat_room_detail'),
    path('rooms/<uuid:room_id>/messages/', room_messages, name='room_messages'),
    path('rooms/<uuid:room_id>/read/', mark_room_read, name='mark_room_read'),
    
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
]