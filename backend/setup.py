#!/usr/bin/env python3
"""
Lunr Backend Setup Script
Run this script to set up the backend for development or production
"""

import os
import sys
import subprocess
import django
from django.core.management import execute_from_command_line

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"\n🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e.stderr}")
        return False

def setup_backend():
    """Main setup function"""
    print("🚀 Setting up Lunr Backend...")
    
    # Check if virtual environment exists
    if not os.path.exists('venv') and not os.path.exists('.venv'):
        print("\n📦 Creating virtual environment...")
        if not run_command("python -m venv venv", "Virtual environment creation"):
            return False
    
    # Install requirements
    pip_cmd = "venv\\Scripts\\pip" if os.name == 'nt' else "venv/bin/pip"
    if not run_command(f"{pip_cmd} install -r requirements.txt", "Installing requirements"):
        return False
    
    # Set up Django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    django.setup()
    
    # Run migrations
    print("\n🗄️ Setting up database...")
    try:
        execute_from_command_line(['manage.py', 'makemigrations'])
        execute_from_command_line(['manage.py', 'migrate'])
        print("✅ Database setup completed")
    except Exception as e:
        print(f"❌ Database setup failed: {e}")
        return False
    
    # Create superuser (optional)
    try:
        from django.contrib.auth import get_user_model
        User = get_user_model()
        if not User.objects.filter(is_superuser=True).exists():
            print("\n👤 Creating superuser...")
            execute_from_command_line(['manage.py', 'createsuperuser'])
    except KeyboardInterrupt:
        print("\n⏭️ Skipping superuser creation")
    
    # Populate initial data
    try:
        print("\n📊 Populating initial data...")
        execute_from_command_line(['manage.py', 'populate_data'])
        print("✅ Initial data populated")
    except Exception as e:
        print(f"❌ Data population failed: {e}")
    
    # Create media directories
    media_dirs = ['media', 'media/avatars', 'media/room_avatars', 'media/files']
    for directory in media_dirs:
        os.makedirs(directory, exist_ok=True)
    print("✅ Media directories created")
    
    print("\n🎉 Lunr Backend setup completed successfully!")
    print("\n📋 Next steps:")
    print("1. Update your .env file with production settings")
    print("2. Configure Redis for WebSocket support")
    print("3. Set up file storage (AWS S3) for production")
    print("4. Configure push notifications (FCM)")
    print("5. Run: python manage.py runserver")
    
    return True

if __name__ == "__main__":
    success = setup_backend()
    sys.exit(0 if success else 1)