#!/usr/bin/env python3
"""
Sync Custom Formats from Radarr to Sonarr
This script copies custom formats (like H.264 preference) from Radarr to Sonarr
"""

import requests
import json
import os
import sys

# Configuration from environment variables
RADARR_URL = os.getenv("RADARR_URL", "http://radarr:7878")
RADARR_API_KEY = os.getenv("RADARR_API_KEY", "")
SONARR_URL = os.getenv("SONARR_URL", "http://sonarr:8989")
SONARR_API_KEY = os.getenv("SONARR_API_KEY", "")

# Check if API keys are set
if not RADARR_API_KEY or not SONARR_API_KEY:
    print("ERROR: API keys not set")
    print("\nPlease set the following environment variables:")
    print("  export RADARR_API_KEY='your-radarr-api-key'")
    print("  export SONARR_API_KEY='your-sonarr-api-key'")
    print("\nTo find your API keys:")
    print("  - Radarr: Settings → General → Security → API Key")
    print("  - Sonarr: Settings → General → Security → API Key")
    sys.exit(1)

def get_radarr_custom_formats():
    """Get all custom formats from Radarr"""
    response = requests.get(
        f"{RADARR_URL}/api/v3/customformat",
        headers={"X-Api-Key": RADARR_API_KEY}
    )
    response.raise_for_status()
    return response.json()

def get_sonarr_custom_formats():
    """Get all custom formats from Sonarr"""
    response = requests.get(
        f"{SONARR_URL}/api/v3/customformat",
        headers={"X-Api-Key": SONARR_API_KEY}
    )
    response.raise_for_status()
    return response.json()

def create_sonarr_custom_format(custom_format):
    """Create a custom format in Sonarr"""
    # Remove ID and includeCustomFormatWhenRenaming (not compatible)
    cf_data = custom_format.copy()
    if 'id' in cf_data:
        del cf_data['id']

    response = requests.post(
        f"{SONARR_URL}/api/v3/customformat",
        headers={"X-Api-Key": SONARR_API_KEY},
        json=cf_data
    )
    response.raise_for_status()
    return response.json()

def main():
    print("=== Syncing Custom Formats from Radarr to Sonarr ===\n")

    # Get custom formats from both
    print("Fetching Radarr custom formats...")
    radarr_formats = get_radarr_custom_formats()
    print(f"Found {len(radarr_formats)} custom formats in Radarr")

    print("\nFetching Sonarr custom formats...")
    sonarr_formats = get_sonarr_custom_formats()
    sonarr_format_names = {cf['name'] for cf in sonarr_formats}
    print(f"Found {len(sonarr_formats)} custom formats in Sonarr")

    # Sync formats
    print("\nSyncing custom formats...\n")
    created_count = 0
    skipped_count = 0

    for radarr_cf in radarr_formats:
        name = radarr_cf['name']

        if name in sonarr_format_names:
            print(f"  ⊘ Skipping '{name}' (already exists in Sonarr)")
            skipped_count += 1
            continue

        try:
            create_sonarr_custom_format(radarr_cf)
            print(f"  ✓ Created '{name}' in Sonarr")
            created_count += 1
        except Exception as e:
            print(f"  ✗ Failed to create '{name}': {e}")

    print(f"\n=== Sync Complete ===")
    print(f"Created: {created_count}")
    print(f"Skipped: {skipped_count}")
    print(f"\nNote: You still need to manually configure the scores in:")
    print(f"  Sonarr → Settings → Profiles → Edit your quality profile")
    print(f"  Then assign scores to the custom formats that were just created.")

if __name__ == '__main__':
    main()
