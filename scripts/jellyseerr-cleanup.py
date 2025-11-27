#!/usr/bin/env python3
"""
Jellyseerr Cleanup Script
Removes media and requests from Jellyseerr when content no longer exists in Jellyfin
This allows users to re-request deleted content
"""

import os
import sys
import json
import requests
from datetime import datetime

# Configuration
JELLYSEERR_URL = os.getenv('JELLYSEERR_URL', 'http://jellyseerr:5055')
JELLYSEERR_API_KEY = os.getenv('JELLYSEERR_API_KEY', '')
JELLYFIN_URL = os.getenv('JELLYFIN_URL', 'http://jellyfin:8096')
JELLYFIN_API_KEY = os.getenv('JELLYFIN_API_KEY', '')

# Check if API keys are set
if not JELLYSEERR_API_KEY:
    print("ERROR: JELLYSEERR_API_KEY environment variable not set")
    print("\nGet API key from: https://requests.mykyta-ryasny.dev/settings/main")
    print("Copy the 'API Key' value from the settings page")
    sys.exit(1)

if not JELLYFIN_API_KEY:
    print("ERROR: JELLYFIN_API_KEY environment variable not set")
    sys.exit(1)

# Headers
jellyseerr_headers = {
    'X-Api-Key': JELLYSEERR_API_KEY
}

jellyfin_headers = {
    'X-Emby-Token': JELLYFIN_API_KEY
}

def check_jellyfin_item_exists(jellyfin_media_id):
    """Check if item exists in Jellyfin"""
    if not jellyfin_media_id:
        return False

    try:
        response = requests.get(
            f'{JELLYFIN_URL}/Items/{jellyfin_media_id}',
            headers=jellyfin_headers,
            timeout=5
        )
        return response.status_code == 200
    except Exception as e:
        print(f"    Error checking Jellyfin item {jellyfin_media_id}: {e}")
        return True  # Assume exists to avoid accidental deletion

def get_jellyseerr_media():
    """Get all media from Jellyseerr"""
    try:
        # Get all media with status 5 (AVAILABLE) or 4 (PARTIALLY_AVAILABLE)
        # Status values: 1=UNKNOWN, 2=PENDING, 3=PROCESSING, 4=PARTIALLY_AVAILABLE, 5=AVAILABLE
        response = requests.get(
            f'{JELLYSEERR_URL}/api/v1/media',
            headers=jellyseerr_headers,
            params={'take': 1000}  # Get up to 1000 items
        )
        response.raise_for_status()

        data = response.json()
        return data.get('results', [])
    except Exception as e:
        print(f"Error getting media from Jellyseerr: {e}")
        return []

def delete_jellyseerr_media(media_id):
    """Delete media from Jellyseerr (also deletes associated requests)"""
    try:
        response = requests.delete(
            f'{JELLYSEERR_URL}/api/v1/media/{media_id}',
            headers=jellyseerr_headers
        )
        return response.status_code in [200, 204]
    except Exception as e:
        print(f"    Error deleting media: {e}")
        return False

def main():
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting Jellyseerr cleanup...")
    print(f"Jellyseerr URL: {JELLYSEERR_URL}")
    print(f"Jellyfin URL: {JELLYFIN_URL}")

    # Get all media from Jellyseerr
    print("\nFetching media from Jellyseerr...")
    media_items = get_jellyseerr_media()
    print(f"Found {len(media_items)} media items in Jellyseerr")

    # Check each media item
    deleted_count = 0
    missing_items = []

    for item in media_items:
        media_id = item.get('id')
        media_type = item.get('mediaType', 'unknown')
        title = item.get('title', 'Unknown')
        status = item.get('status')
        jellyfin_media_id = item.get('jellyfinMediaId')

        # Only check items that are marked as available
        if status not in [4, 5]:  # PARTIALLY_AVAILABLE or AVAILABLE
            continue

        # Check if the item still exists in Jellyfin
        if jellyfin_media_id and not check_jellyfin_item_exists(jellyfin_media_id):
            missing_items.append({
                'id': media_id,
                'title': title,
                'type': media_type,
                'jellyfin_id': jellyfin_media_id
            })
            print(f"  Missing: {title} ({media_type})")
            print(f"           Jellyfin ID: {jellyfin_media_id}")

    # Show summary
    if not missing_items:
        print("\n✓ No missing items found. Database is clean!")
        return

    print(f"\nFound {len(missing_items)} missing items.")
    print("\nDeleting missing items from Jellyseerr...")

    for item in missing_items:
        if delete_jellyseerr_media(item['id']):
            print(f"  ✓ Deleted: {item['title']}")
            print(f"    This content can now be requested again!")
            deleted_count += 1
        else:
            print(f"  ✗ Failed to delete: {item['title']}")

    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Cleanup complete.")
    print(f"Deleted {deleted_count} of {len(missing_items)} missing items.")
    print(f"Users can now re-request this content!")

if __name__ == '__main__':
    main()
