# backend/chat/views.py
from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from django.db.models import Q, Count, Prefetch
from django.shortcuts import get_object_or_404
from .models import (
    User, Message, ChatRoom, RoomMembership, UserBlock, UserReport,
    Notification, UserSettings, Update, Tool, MessageRead, Contact
)
from .serializers import (
    UserSerializer, RegisterSerializer, MessageSerializer, ChatRoomSerializer,
    NotificationSerializer, UserSettingsSerializer, UpdateSerializer,
    ToolSerializer, UserBlockSerializer, UserReportSerializer, UserProfileSerializer,
    ContactSerializer
)
import socketio
import json
from django.core.serializers.json import DjangoJSONEncoder

# Authentication Views
@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response({
            'user': UserSerializer(user).data,
            'message': 'Welcome to Lunr!'
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not username or not password:
        return Response({'error': 'Username and password required'}, status=400)
    
    try:
        user = User.objects.get(username=username)
        if user.check_password(password):
            user.online_status = True
            user.last_seen = timezone.now()
            user.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': UserSerializer(user).data
            })
        else:
            return Response({'error': 'Invalid credentials'}, status=401)
    except User.DoesNotExist:
        return Response({'error': 'Invalid credentials'}, status=401)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    user = request.user
    user.online_status = False
    user.last_seen = timezone.now()
    user.save()
    return Response({'message': 'Logged out successfully'})

# User Profile Views
@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    if request.method == 'GET':
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data)
    
    elif request.method == 'PUT':
        serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_users(request):
    query = request.GET.get('q', '')
    if len(query) < 2:
        return Response([])
    
    blocked_users = UserBlock.objects.filter(blocker=request.user).values_list('blocked_id', flat=True)
    users = User.objects.filter(
        username__icontains=query
    ).exclude(id=request.user.id).exclude(id__in=blocked_users)
    
    return Response(UserSerializer(users, many=True).data)

# Chat Room Views
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def chat_rooms(request):
    if request.method == 'GET':
        rooms = ChatRoom.objects.filter(
            members=request.user
        ).prefetch_related('members', 'messages').order_by('-updated_at')
        serializer = ChatRoomSerializer(rooms, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        data = request.data
        room_type = data.get('room_type', 'group')
        
        if room_type == 'direct':
            other_user_id = data.get('other_user_id')
            if not other_user_id:
                return Response({'error': 'other_user_id required for direct chat'}, status=400)
            
            try:
                other_user_id = int(other_user_id)
            except (ValueError, TypeError):
                return Response({'error': 'Invalid user ID'}, status=400)

            # Check if direct room already exists
            # Find rooms where BOTH users are members and room_type is 'direct'
            existing_rooms = ChatRoom.objects.filter(
                room_type='direct',
                members=request.user
            ).filter(
                members__id=other_user_id
            )
            
            # Verify exact membership count to avoid group chats that might have played tricks (though unlikely with room_type='direct')
            for room in existing_rooms:
                if room.members.count() == 2:
                    return Response(ChatRoomSerializer(room).data)
            
            # Create new direct room
            room = ChatRoom.objects.create(
                room_type='direct',
                created_by=request.user
            )
            RoomMembership.objects.create(user=request.user, room=room, role='admin')
            RoomMembership.objects.create(user_id=other_user_id, room=room, role='member')
        
        else:
            # Create group room
            room = ChatRoom.objects.create(
                name=data.get('name', ''),
                description=data.get('description', ''),
                room_type='group',
                created_by=request.user,
                is_private=data.get('is_private', False)
            )
            # Add creator as admin
            RoomMembership.objects.create(user=request.user, room=room, role='admin')
            
            # Add other members
            members_ids = data.get('members', [])
            for member_id in members_ids:
                try:
                    user = User.objects.get(id=int(member_id))
                    if user != request.user:
                        RoomMembership.objects.get_or_create(user=user, room=room, role='member')
                except (User.DoesNotExist, ValueError):
                    pass
            
            # Create initial system/welcome message
            Message.objects.create(
                room=room,
                sender=request.user,
                content=f'Group "{room.name}" created',
                message_type='system' 
            )
        
        return Response(ChatRoomSerializer(room).data, status=201)

@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def chat_room_detail(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id, members=request.user)
    
    if request.method == 'GET':
        return Response(ChatRoomSerializer(room).data)
    
    elif request.method == 'PUT':
        membership = RoomMembership.objects.get(user=request.user, room=room)
        if membership.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        
        serializer = ChatRoomSerializer(room, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)
    
    elif request.method == 'DELETE':
        membership = RoomMembership.objects.get(user=request.user, room=room)
        if room.room_type == 'group' and membership.role == 'admin':
            room.delete()
        else:
            membership.delete()
        return Response({'message': 'Left room successfully'})

# Message Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def room_messages(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id, members=request.user)
    messages = Message.objects.filter(
        room=room, deleted_at__isnull=True
    ).select_related('sender').order_by('timestamp')
    
    # Mark messages as read
    unread_messages = messages.exclude(sender=request.user)
    for message in unread_messages:
        MessageRead.objects.get_or_create(message=message, user=request.user)
    
    return Response(MessageSerializer(messages, many=True).data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_room_read(request, room_id):
    room = get_object_or_404(ChatRoom, id=room_id, members=request.user)
    # Efficiently find messages not read by user
    # We want messages in this room, NOT sent by user, that do NOT have a MessageRead for this user
    unread_messages = Message.objects.filter(
        room=room
    ).exclude(
        sender=request.user
    ).exclude(
        messageread__user=request.user
    )
    
    # Bulk create MessageRead objects
    reads = [MessageRead(message=msg, user=request.user) for msg in unread_messages]
    MessageRead.objects.bulk_create(reads, ignore_conflicts=True)
    
    return Response({'message': 'Messages marked as read', 'count': len(reads)})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_message(request):
    room_id = request.data.get('room_id')
    content = request.data.get('content')
    message_type = request.data.get('message_type', 'text')
    reply_to_id = request.data.get('reply_to')
    
    if not room_id or not content:
        return Response({'error': 'room_id and content required'}, status=400)
    
    room = get_object_or_404(ChatRoom, id=room_id, members=request.user)
    
    message_data = {
        'sender': request.user,
        'room': room,
        'content': content,
        'message_type': message_type
    }
    
    if reply_to_id:
        reply_message = get_object_or_404(Message, id=reply_to_id, room=room)
        message_data['reply_to'] = reply_message
    
    message = Message.objects.create(**message_data)
    room.updated_at = timezone.now()
    room.save()
    
    # Emit to Socket.IO
    try:
        # Connect to the same Redis as the server
        mgr = socketio.RedisManager('redis://127.0.0.1:6379/0', write_only=True)
        serializer = MessageSerializer(message)
        # Serialize data to ensure UUIDs/Datetimes are handled
        data = json.loads(json.dumps(serializer.data, cls=DjangoJSONEncoder))
        mgr.emit('message', data, room=str(room.id))
    except Exception as e:
        print(f"Socket emit error: {e}")
    
    return Response(MessageSerializer(message).data, status=201)

@api_view(['PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def message_detail(request, message_id):
    message = get_object_or_404(Message, id=message_id, sender=request.user)
    
    if request.method == 'PUT':
        content = request.data.get('content')
        if content:
            message.content = content
            message.edited_at = timezone.now()
            message.save()
            return Response(MessageSerializer(message).data)
        return Response({'error': 'Content required'}, status=400)
    
    elif request.method == 'DELETE':
        message.deleted_at = timezone.now()
        message.save()
        return Response({'message': 'Message deleted'})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_reaction(request, message_id):
    message = get_object_or_404(Message, id=message_id)
    emoji = request.data.get('emoji')
    
    if not emoji:
        return Response({'error': 'Emoji required'}, status=400)
    
    reactions = message.reactions or {}
    if emoji not in reactions:
        reactions[emoji] = []
    
    user_id = str(request.user.id)
    if user_id in reactions[emoji]:
        reactions[emoji].remove(user_id)
        if not reactions[emoji]:
            del reactions[emoji]
    else:
        reactions[emoji].append(user_id)
    
    message.reactions = reactions
    message.save()
    
    return Response({'reactions': reactions})

# Settings Views
@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def user_settings(request):
    settings, created = UserSettings.objects.get_or_create(user=request.user)
    
    if request.method == 'GET':
        return Response(UserSettingsSerializer(settings).data)
    
    elif request.method == 'PUT':
        serializer = UserSettingsSerializer(settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

# Privacy Views
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def block_user(request):
    user_id = request.data.get('user_id')
    if not user_id:
        return Response({'error': 'user_id required'}, status=400)
    
    user_to_block = get_object_or_404(User, id=user_id)
    block, created = UserBlock.objects.get_or_create(
        blocker=request.user,
        blocked=user_to_block
    )
    
    return Response({'message': 'User blocked successfully'})

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def unblock_user(request, user_id):
    UserBlock.objects.filter(
        blocker=request.user,
        blocked_id=user_id
    ).delete()
    
    return Response({'message': 'User unblocked successfully'})

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def blocked_users(request):
    blocks = UserBlock.objects.filter(blocker=request.user).select_related('blocked')
    return Response(UserBlockSerializer(blocks, many=True).data)

# Notification Views
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notifications(request):
    notifications = Notification.objects.filter(user=request.user).order_by('-created_at')
    return Response(NotificationSerializer(notifications, many=True).data)

@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    notification = get_object_or_404(Notification, id=notification_id, user=request.user)
    notification.is_read = True
    notification.save()
    return Response({'message': 'Notification marked as read'})

# App Features
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def updates(request):
    updates = Update.objects.all().order_by('-release_date')
    return Response(UpdateSerializer(updates, many=True).data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tools(request):
    tools = Tool.objects.filter(is_active=True)
    return Response(ToolSerializer(tools, many=True).data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def report_user(request):
    serializer = UserReportSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save(reporter=request.user)
        return Response({'message': 'Report submitted successfully'}, status=201)
    return Response(serializer.errors, status=400)

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def contacts(request):
    if request.method == 'GET':
        contacts = Contact.objects.filter(user=request.user)
        return Response(ContactSerializer(contacts, many=True).data)
    
    elif request.method == 'POST':
        username = request.data.get('username')
        if not username:
            return Response({'error': 'Username required'}, status=400)
            
        try:
            contact_user = User.objects.get(username=username)
            if contact_user == request.user:
                return Response({'error': 'Cannot add yourself'}, status=400)
                
            contact, created = Contact.objects.get_or_create(
                user=request.user,
                contact_user=contact_user
            )
            
            if not created:
                return Response({
                    'message': 'Contact already exists', 
                    'contact': ContactSerializer(contact).data
                })
                
            return Response(ContactSerializer(contact).data, status=201)
            
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)

@api_view(['PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def contact_detail(request, contact_id):
    contact = get_object_or_404(Contact, id=contact_id, user=request.user)
    
    if request.method == 'PUT':
        alias = request.data.get('alias')
        if alias is not None:
            contact.alias = alias
            contact.save()
            return Response(ContactSerializer(contact).data)
        return Response({'error': 'Alias required'}, status=400)
        
    elif request.method == 'DELETE':
        contact.delete()
        return Response({'message': 'Contact deleted'})