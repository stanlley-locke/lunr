# backend/core/asgi.py
import os
from django.core.asgi import get_asgi_application

# Set settings module BEFORE any Django imports
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Import AFTER setting the environment
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import chat.routing

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(chat.routing.websocket_urlpatterns)
    ),
})