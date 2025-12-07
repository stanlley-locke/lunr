import socketio
import os
import jwt
from django.conf import settings
from urllib.parse import parse_qs

# Use Redis as message queue for scaling and to allow emitting from views
# In Codespaces, Redis is at 127.0.0.1:6379
mgr = socketio.AsyncRedisManager('redis://127.0.0.1:6379/0')
sio = socketio.AsyncServer(async_mode='asgi', client_manager=mgr, cors_allowed_origins='*')

@sio.event
async def connect(sid, environ):
    query_string = environ.get('QUERY_STRING', b'').decode('utf-8')
    params = parse_qs(query_string)
    token = params.get('token', [None])[0]
    
    if not token:
        print("No token provided")
        return False  # Reject connection

    try:
        # Verify token
        # SimpleJWT uses HS256 by default with SECRET_KEY
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=['HS256'])
        user_id = payload.get('user_id')
        if not user_id:
            print("No user_id in token")
            return False
            
        # Store user_id in session
        await sio.save_session(sid, {'user_id': user_id})
        print(f"User {user_id} connected with sid {sid}")
    except Exception as e:
        print(f"Token verification failed: {e}")
        return False

@sio.event
async def disconnect(sid):
    print(f"Client {sid} disconnected")

@sio.event
async def join(sid, data):
    # Handle both string and dict payload
    if isinstance(data, dict):
        room_id = data.get('room_id')
    else:
        room_id = data
        
    if room_id:
        await sio.enter_room(sid, room_id)
        print(f"Client {sid} joined room {room_id}")

@sio.event
async def leave(sid, data):
    if isinstance(data, dict):
        room_id = data.get('room_id')
    else:
        room_id = data
        
    if room_id:
        await sio.leave_room(sid, room_id)
        print(f"Client {sid} left room {room_id}")
