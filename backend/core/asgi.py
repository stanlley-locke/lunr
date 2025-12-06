import os
from django.core.asgi import get_asgi_application

# 1. Set the settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# 2. Initialize Django ASGI application EARLY
# This line is crucial: it forces Django to load apps/models immediately.
django_asgi_app = get_asgi_application()

# 3. Import your project code AFTER step 2
# Now that Django is ready, these imports won't throw AppRegistryNotReady
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
import chat.routing

application = ProtocolTypeRouter({
    # 4. Use the variable we created in step 2
    "http": django_asgi_app,
    "websocket": AuthMiddlewareStack(
        URLRouter(chat.routing.websocket_urlpatterns)
    ),
})