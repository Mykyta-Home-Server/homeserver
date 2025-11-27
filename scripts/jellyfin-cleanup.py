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

# Check if API key is set
if not API_KEY:
    print("ERROR: JELLYFIN_API_KEY environment variable not set")
    print("\nTo create an API key:")
    print("1. Go to: https://streaming.mykyta-ryasny.dev")
    print("2. Log in as admin")
    print("3. Go to: Dashboard → Advanced → API Keys")
    print("4. Click: '+ New API Key'")
    print("5. Name: 'Cleanup Script'")
    print("6. Copy the key")
    print("\nThen run:")
    print("  export JELLYFIN_API_KEY='your-api-key-here'")
    print("  python3 /opt/homeserver/scripts/jellyfin-cleanup.py")
    sys.exit(1)

# Headers for API requests
headers = {
    'X-Emby-Token': API_KEY
}

def check_file_exists(file_path):
    """Check if file exists inside Jellyfin container"""
    try:
        result = os.system(f'docker exec jellyfin test -f "{file_path}" 2>/dev/null')
        return result == 0
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

        # Get all items for this user
        params = {
            'Recursive': 'true',
            'IncludeItemTypes': 'Movie,Episode',
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
    """Delete an item from Jellyfin"""
    try:
        response = requests.delete(
            f'{JELLYFIN_URL}/Items/{item_id}',
            headers=headers
        )
        return response.status_code in [200, 204]
    except Exception as e:
        print(f"Error deleting {item_name}: {e}")
        return False

def main():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting Jellyfin cleanup...")
    print(f"Jellyfin URL: {JELLYFIN_URL}")

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

    # Show summary and confirm deletion
    if not missing_items:
        print("\n✓ No missing items found. Database is clean!")
        return

    print(f"\nFound {len(missing_items)} missing items.")
    print("\nDeleting missing items from Jellyfin database...")

    for item in missing_items:
        if delete_item(item['id'], item['name']):
            print(f"  ✓ Deleted: {item['name']}")
            deleted_count += 1
        else:
            print(f"  ✗ Failed to delete: {item['name']}")

    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Cleanup complete.")
    print(f"Deleted {deleted_count} of {len(missing_items)} missing items.")

if __name__ == '__main__':
    main()
