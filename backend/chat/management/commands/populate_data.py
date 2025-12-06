from django.core.management.base import BaseCommand
from chat.models import Update, Tool, User, UserSettings

class Command(BaseCommand):
    help = 'Populate initial data for Lunr app'

    def handle(self, *args, **options):
        # Create sample updates
        updates_data = [
            {
                'title': 'Enhanced Group Chat Features',
                'description': 'Added group creation, admin controls, and member management features.',
                'version': '2.1.0',
                'update_type': 'feature',
                'is_critical': False
            },
            {
                'title': 'Message Reactions & Replies',
                'description': 'Users can now react to messages with emojis and reply to specific messages.',
                'version': '2.0.5',
                'update_type': 'feature',
                'is_critical': False
            },
            {
                'title': 'Privacy Controls Update',
                'description': 'Enhanced privacy settings including read receipts, last seen, and profile visibility.',
                'version': '2.0.3',
                'update_type': 'feature',
                'is_critical': False
            },
            {
                'title': 'Security Patch',
                'description': 'Fixed potential security vulnerabilities in message encryption.',
                'version': '2.0.2',
                'update_type': 'security',
                'is_critical': True
            }
        ]

        for update_data in updates_data:
            Update.objects.get_or_create(
                version=update_data['version'],
                defaults=update_data
            )

        # Create sample tools
        tools_data = [
            {
                'name': 'QR Code Scanner',
                'description': 'Scan QR codes to quickly add contacts or join groups',
                'icon': 'qr_code_scanner',
                'url': '',
                'is_active': True
            },
            {
                'name': 'Voice Recorder',
                'description': 'Record and send voice messages',
                'icon': 'mic',
                'url': '',
                'is_active': True
            },
            {
                'name': 'Location Sharing',
                'description': 'Share your current location with contacts',
                'icon': 'location_on',
                'url': '',
                'is_active': True
            },
            {
                'name': 'File Manager',
                'description': 'Manage and share files from your device',
                'icon': 'folder',
                'url': '',
                'is_active': True
            },
            {
                'name': 'Backup & Restore',
                'description': 'Backup your chats and restore them on new devices',
                'icon': 'backup',
                'url': '',
                'is_active': True
            },
            {
                'name': 'Theme Customizer',
                'description': 'Customize app appearance with themes and colors',
                'icon': 'palette',
                'url': '',
                'is_active': True
            }
        ]

        for tool_data in tools_data:
            Tool.objects.get_or_create(
                name=tool_data['name'],
                defaults=tool_data
            )

        # Create settings for existing users without settings
        users_without_settings = User.objects.filter(usersettings__isnull=True)
        for user in users_without_settings:
            UserSettings.objects.create(user=user)

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully populated data:\n'
                f'- {len(updates_data)} updates\n'
                f'- {len(tools_data)} tools\n'
                f'- Settings for {users_without_settings.count()} users'
            )
        )