#!/usr/bin/env python3
"""
Jellyfin Cleanup Script
Removes items from Jellyfin database that no longer exist on disk
"""

import os
import sys
import json
import requests
from datetime import datetime
from pathlib import Path

# Configuration
JELLYFIN_URL = os.getenv('JELLYFIN_URL', 'http://jellyfin:8096')
API_KEY = os.getenv('JELLYFIN_API_KEY', '')

# Headers for API requests (will be set after authentication)
headers = {}

def authenticate():
    """Authenticate with Jellyfin using API key"""
    global headers

    # Use API key authentication
    # Note: Since Jellyfin is configured with Authentik SSO (OIDC),
    # local username/password authentication is no longer supported.
    # API keys are the recommended method for script/automation access.
    if API_KEY:
        headers['X-Emby-Token'] = API_KEY
        print("✓ Using API key authentication")
        return True

    print("ERROR: JELLYFIN_API_KEY environment variable not set")
    print("\nTo create an API key:")
    print("  1. Log in to Jellyfin web interface")
    print("  2. Go to Dashboard → Advanced → API Keys")
    print("  3. Click 'New API Key' and copy the generated key")
    print("  4. Set JELLYFIN_API_KEY in .env file")
    sys.exit(1)

def check_file_exists(file_path):
    """Check if file exists on mounted media volume"""
    try:
        # Check if file exists at the given path
        # Jellyfin may use either /media/... or /data/media/... depending on config
        # Container has media mounted at /data/media/

        if file_path.startswith('/media/'):
            # Convert /media/ to /data/media/ for container path
            local_path = file_path.replace('/media/', '/data/media/', 1)
        elif file_path.startswith('/data/media/'):
            # Already using container path
            local_path = file_path
        else:
            # Unexpected path format, log warning
            print(f"  WARNING: Unexpected path format: {file_path}")
            return True  # Assume exists to avoid accidental deletion

        return os.path.exists(local_path)
    except Exception as e:
        print(f"Error checking file: {e}")
        return True  # Assume exists to avoid accidental deletion

def get_all_users():
    """Get all Jellyfin users"""
    try:
        response = requests.get(
            f'{JELLYFIN_URL}/Users',
            headers=headers
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error getting users from Jellyfin: {e}")
        return []

def get_all_items():
    """Get all movies and episodes from Jellyfin (across all users)"""
    try:
        # Get all users first
        users = get_all_users()
        if not users:
            print("No users found")
            return []

        # Use first user to get all items
        user_id = users[0]['Id']

        # Get all items for this user (Movies, TV Series, and Episodes)
        params = {
            'Recursive': 'true',
            'IncludeItemTypes': 'Movie,Series,Episode',
            'Fields': 'Path'
        }

        response = requests.get(
            f'{JELLYFIN_URL}/Users/{user_id}/Items',
            headers=headers,
            params=params
        )
        response.raise_for_status()

        data = response.json()
        return data.get('Items', [])

    except Exception as e:
        print(f"Error getting items from Jellyfin: {e}")
        sys.exit(1)

def delete_item(item_id, item_name):
    """Delete an item from Jellyfin database"""
    try:
        response = requests.delete(
            f'{JELLYFIN_URL}/Items/{item_id}',
            headers=headers
        )

        if response.status_code in [200, 204]:
            return True

        # Log the failure reason
        print(f"      DELETE failed: HTTP {response.status_code}")
        if response.text:
            print(f"      Response: {response.text[:200]}")

        return False
    except Exception as e:
        print(f"      Error deleting {item_name}: {e}")
        return False

def get_libraries():
    """Get all media libraries"""
    try:
        # Get all users first
        users = get_all_users()
        if not users:
            print("No users found")
            return []

        # Use first user to get libraries
        user_id = users[0]['Id']

        response = requests.get(
            f'{JELLYFIN_URL}/Users/{user_id}/Items',
            headers=headers,
            params={
                'Recursive': 'false',
                'IncludeItemTypes': 'CollectionFolder'
            }
        )
        response.raise_for_status()

        data = response.json()
        return data.get('Items', [])

    except Exception as e:
        print(f"Error getting libraries from Jellyfin: {e}")
        return []

def main():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting Jellyfin cleanup...")
    print(f"Jellyfin URL: {JELLYFIN_URL}")

    # Authenticate first
    authenticate()

    # Get all items
    print("Fetching items from Jellyfin...")
    items = get_all_items()
    print(f"Found {len(items)} items in Jellyfin")

    # Check each item
    deleted_count = 0
    missing_items = []

    for item in items:
        item_id = item.get('Id')
        item_name = item.get('Name', 'Unknown')
        item_type = item.get('Type', 'Unknown')
        item_path = item.get('Path')

        if not item_path:
            # Skip items without a file path (like collections, playlists, etc.)
            continue

        # Check if file exists
        if not check_file_exists(item_path):
            missing_items.append({
                'id': item_id,
                'name': item_name,
                'type': item_type,
                'path': item_path
            })
            print(f"  Missing: {item_name} ({item_type})")
            print(f"           Path: {item_path}")

    # Show summary and delete missing items
    if not missing_items:
        print("\n✓ No missing items found. Database is clean!")
        return

    print(f"\nFound {len(missing_items)} missing items.")
    print(f"\n🗑️  Deleting missing items from Jellyfin database...")

    deleted_count = 0
    failed_count = 0

    for item in missing_items:
        item_id = item['id']
        item_name = item['name']
        item_type = item['type']

        if delete_item(item_id, item_name):
            print(f"   ✓ Deleted: {item_name} ({item_type})")
            deleted_count += 1
        else:
            print(f"   ✗ Failed to delete: {item_name} ({item_type})")
            failed_count += 1

    # Summary
    if deleted_count > 0:
        print(f"\n✓ Successfully deleted {deleted_count} missing item(s)")

    if failed_count > 0:
        print(f"\n⚠️  Failed to delete {failed_count} item(s)")

    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Cleanup complete.")

if __name__ == '__main__':
    main()
