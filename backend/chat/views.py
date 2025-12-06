# backend/chat/views.py
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from django.db.models import Q, Count
from django.shortcuts import get_object_or_404
from .models import User, Message
from .serializers import UserSerializer, RegisterSerializer, MessageSerializer

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

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_users(request):
    query = request.GET.get('q', '')
    if len(query) < 2:
        return Response([])
    users = User.objects.filter(username__icontains=query).exclude(id=request.user.id)
    return Response(UserSerializer(users, many=True).data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_conversations(request):
    user = request.user
    # Get all users this user has chatted with
    conversations = Message.objects.filter(
        Q(sender=user) | Q(receiver=user)
    ).values('sender', 'receiver').annotate(last_message=Count('id')).order_by('-last_message')
    
    user_ids = set()
    for conv in conversations:
        if conv['sender'] != user.id:
            user_ids.add(conv['sender'])
        if conv['receiver'] != user.id:
            user_ids.add(conv['receiver'])
    
    contacts = User.objects.filter(id__in=user_ids)
    return Response(UserSerializer(contacts, many=True).data)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_messages(request, user_id):
    other_user = get_object_or_404(User, id=user_id)
    messages = Message.objects.filter(
        (Q(sender=request.user) & Q(receiver=other_user)) |
        (Q(sender=other_user) & Q(receiver=request.user))
    ).order_by('timestamp')
    
    # Mark messages as read
    unread = messages.filter(sender=other_user, receiver=request.user, is_read=False)
    unread.update(is_read=True, read_at=timezone.now())
    
    return Response(MessageSerializer(messages, many=True).data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_message(request):
    receiver_id = request.data.get('receiver_id')
    content = request.data.get('content')
    
    if not receiver_id or not content:
        return Response({'error': 'receiver_id and content required'}, status=400)
    
    try:
        receiver = User.objects.get(id=receiver_id)
        if receiver == request.user:
            return Response({'error': 'Cannot message yourself'}, status=400)
        
        message = Message.objects.create(
            sender=request.user,
            receiver=receiver,
            content=content
        )
        return Response(MessageSerializer(message).data, status=201)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=404)