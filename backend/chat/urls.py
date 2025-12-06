# backend/chat/urls.py
from django.urls import path
from .views import (
    register, login, logout, search_users,
    get_conversations, get_messages, send_message
)

urlpatterns = [
    path('auth/register/', register, name='register'),
    path('auth/login/', login, name='login'),
    path('auth/logout/', logout, name='logout'),
    path('users/search/', search_users, name='search_users'),
    path('conversations/', get_conversations, name='conversations'),
    path('messages/<int:user_id>/', get_messages, name='get_messages'),
    path('messages/', send_message, name='send_message'),
]