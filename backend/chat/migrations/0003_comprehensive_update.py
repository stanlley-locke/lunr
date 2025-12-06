# Generated migration for comprehensive Lunr update

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('chat', '0002_message_read_at_user_last_seen_and_more'),
    ]

    operations = [
        # Update User model
        migrations.AddField(
            model_name='user',
            name='avatar',
            field=models.ImageField(blank=True, null=True, upload_to='avatars/'),
        ),
        migrations.AddField(
            model_name='user',
            name='bio',
            field=models.TextField(blank=True, max_length=500),
        ),
        migrations.AddField(
            model_name='user',
            name='phone_number',
            field=models.CharField(blank=True, max_length=15),
        ),
        migrations.AddField(
            model_name='user',
            name='date_of_birth',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='user',
            name='status_message',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='user',
            name='is_verified',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='user',
            name='show_last_seen',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='user',
            name='show_read_receipts',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='user',
            name='show_profile_photo',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='user',
            name='show_status',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='user',
            name='typing_status',
            field=models.JSONField(default=dict),
        ),
        migrations.AddField(
            model_name='user',
            name='device_tokens',
            field=models.JSONField(default=list),
        ),
        
        # Create ChatRoom model
        migrations.CreateModel(
            name='ChatRoom',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(blank=True, max_length=100)),
                ('description', models.TextField(blank=True)),
                ('room_type', models.CharField(choices=[('direct', 'Direct'), ('group', 'Group')], default='direct', max_length=10)),
                ('avatar', models.ImageField(blank=True, null=True, upload_to='room_avatars/')),
                ('is_private', models.BooleanField(default=False)),
                ('max_members', models.IntegerField(default=100)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_rooms', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        
        # Create RoomMembership model
        migrations.CreateModel(
            name='RoomMembership',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('role', models.CharField(choices=[('admin', 'Admin'), ('member', 'Member')], default='member', max_length=10)),
                ('joined_at', models.DateTimeField(auto_now_add=True)),
                ('is_muted', models.BooleanField(default=False)),
                ('room', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='chat.chatroom')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('user', 'room')},
            },
        ),
        
        # Add members to ChatRoom through RoomMembership
        migrations.AddField(
            model_name='chatroom',
            name='members',
            field=models.ManyToManyField(through='chat.RoomMembership', to=settings.AUTH_USER_MODEL),
        ),
        
        # Update Message model
        migrations.RemoveField(
            model_name='message',
            name='receiver',
        ),
        migrations.AddField(
            model_name='message',
            name='room',
            field=models.ForeignKey(default=uuid.uuid4, on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='chat.chatroom'),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='message',
            name='message_type',
            field=models.CharField(choices=[('text', 'Text'), ('image', 'Image'), ('video', 'Video'), ('audio', 'Audio'), ('file', 'File'), ('location', 'Location'), ('contact', 'Contact'), ('sticker', 'Sticker')], default='text', max_length=20),
        ),
        migrations.AddField(
            model_name='message',
            name='file_url',
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name='message',
            name='file_size',
            field=models.BigIntegerField(null=True),
        ),
        migrations.AddField(
            model_name='message',
            name='thumbnail_url',
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name='message',
            name='reply_to',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='chat.message'),
        ),
        migrations.AddField(
            model_name='message',
            name='forwarded_from',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='forwarded_messages', to='chat.message'),
        ),
        migrations.AddField(
            model_name='message',
            name='edited_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='message',
            name='deleted_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='message',
            name='reactions',
            field=models.JSONField(default=dict),
        ),
        migrations.RemoveField(
            model_name='message',
            name='is_read',
        ),
        
        # Change Message ID to UUID
        migrations.AlterField(
            model_name='message',
            name='id',
            field=models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False),
        ),
        
        # Create MessageRead model
        migrations.CreateModel(
            name='MessageRead',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('read_at', models.DateTimeField(auto_now_add=True)),
                ('message', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='chat.message')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('message', 'user')},
            },
        ),
        
        # Add last_read_message to RoomMembership
        migrations.AddField(
            model_name='roommembership',
            name='last_read_message',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='chat.message'),
        ),
        
        # Create other models
        migrations.CreateModel(
            name='UserBlock',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('blocked', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='blocked_by', to=settings.AUTH_USER_MODEL)),
                ('blocker', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='blocked_users', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'unique_together': {('blocker', 'blocked')},
            },
        ),
        
        migrations.CreateModel(
            name='UserReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('report_type', models.CharField(choices=[('spam', 'Spam'), ('harassment', 'Harassment'), ('inappropriate', 'Inappropriate Content'), ('other', 'Other')], max_length=20)),
                ('description', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('is_resolved', models.BooleanField(default=False)),
                ('reported_user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reports_received', to=settings.AUTH_USER_MODEL)),
                ('reporter', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='reports_made', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('notification_type', models.CharField(choices=[('message', 'New Message'), ('group_invite', 'Group Invite'), ('friend_request', 'Friend Request'), ('system', 'System')], max_length=20)),
                ('title', models.CharField(max_length=100)),
                ('body', models.TextField()),
                ('data', models.JSONField(default=dict)),
                ('is_read', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        
        migrations.CreateModel(
            name='UserSettings',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('push_notifications', models.BooleanField(default=True)),
                ('message_notifications', models.BooleanField(default=True)),
                ('group_notifications', models.BooleanField(default=True)),
                ('sound_enabled', models.BooleanField(default=True)),
                ('vibration_enabled', models.BooleanField(default=True)),
                ('auto_download_media', models.BooleanField(default=True)),
                ('backup_enabled', models.BooleanField(default=False)),
                ('theme', models.CharField(choices=[('light', 'Light'), ('dark', 'Dark')], default='light', max_length=10)),
                ('language', models.CharField(default='en', max_length=10)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
        ),
        
        migrations.CreateModel(
            name='Update',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=200)),
                ('description', models.TextField()),
                ('version', models.CharField(max_length=20)),
                ('update_type', models.CharField(choices=[('feature', 'Feature'), ('bug_fix', 'Bug Fix'), ('security', 'Security')], max_length=20)),
                ('is_critical', models.BooleanField(default=False)),
                ('release_date', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['-release_date'],
            },
        ),
        
        migrations.CreateModel(
            name='Tool',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100)),
                ('description', models.TextField()),
                ('icon', models.CharField(max_length=50)),
                ('url', models.URLField(blank=True)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        
        # Update indexes
        migrations.AlterModelOptions(
            name='message',
            options={'ordering': ['timestamp']},
        ),
        
        # Remove old indexes and add new ones
        migrations.RunSQL(
            "DROP INDEX IF EXISTS chat_message_sender_id_receiver_id_idx;",
            reverse_sql="CREATE INDEX chat_message_sender_id_receiver_id_idx ON chat_message (sender_id, receiver_id);"
        ),
        
        migrations.AddIndex(
            model_name='message',
            index=models.Index(fields=['room', 'timestamp'], name='chat_message_room_timestamp_idx'),
        ),
        migrations.AddIndex(
            model_name='message',
            index=models.Index(fields=['sender'], name='chat_message_sender_idx'),
        ),
    ]