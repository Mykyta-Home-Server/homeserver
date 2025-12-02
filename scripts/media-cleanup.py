#!/usr/bin/env python3
"""
Media Cleanup Script - Jellyseerr as Single Source of Truth

When media is deleted from Jellyseerr, this script:
1. Removes it from Radarr/Sonarr (including files)
2. Removes associated torrents from qBittorrent

Runs via cron to keep everything in sync.
"""

import os
import sys
import json
import requests
from datetime import datetime

# Configuration from environment
JELLYSEERR_URL = os.getenv('JELLYSEERR_URL', 'http://jellyseerr:5055')
RADARR_URL = os.getenv('RADARR_URL', 'http://radarr:7878')
SONARR_URL = os.getenv('SONARR_URL', 'http://sonarr:8989')
QBITTORRENT_URL = os.getenv('QBITTORRENT_URL', 'http://qbittorrent:8080')

JELLYSEERR_API_KEY = os.getenv('JELLYSEERR_API_KEY', '')
RADARR_API_KEY = os.getenv('RADARR_API_KEY', '')
SONARR_API_KEY = os.getenv('SONARR_API_KEY', '')

# Dry run mode - set to False to actually delete
DRY_RUN = os.getenv('DRY_RUN', 'true').lower() == 'true'


def log(msg):
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}")


def get_jellyseerr_media():
    """Get all media tracked in Jellyseerr"""
    try:
        # Get all media requests (approved/available)
        media_ids = {'movies': set(), 'tv': set()}

        # Prepare headers with API key
        headers = {}
        if JELLYSEERR_API_KEY:
            headers['X-Api-Key'] = JELLYSEERR_API_KEY

        # Fetch movies
        page = 1
        while True:
            response = requests.get(
                f'{JELLYSEERR_URL}/api/v1/media',
                headers=headers,
                params={'take': 100, 'skip': (page - 1) * 100},
                timeout=30
            )
            if response.status_code != 200:
                log(f"Failed to fetch Jellyseerr media: {response.status_code}")
                break

            data = response.json()
            results = data.get('results', [])

            if not results:
                break

            for item in results:
                media_type = item.get('mediaType')
                tmdb_id = item.get('tmdbId')
                tvdb_id = item.get('tvdbId')

                if media_type == 'movie' and tmdb_id:
                    media_ids['movies'].add(tmdb_id)
                elif media_type == 'tv' and tvdb_id:
                    media_ids['tv'].add(tvdb_id)

            if len(results) < 100:
                break
            page += 1

        log(f"Jellyseerr tracking: {len(media_ids['movies'])} movies, {len(media_ids['tv'])} TV shows")
        return media_ids

    except Exception as e:
        log(f"Error fetching Jellyseerr media: {e}")
        return {'movies': set(), 'tv': set()}


def get_radarr_movies():
    """Get all movies in Radarr"""
    try:
        response = requests.get(
            f'{RADARR_URL}/api/v3/movie',
            headers={'X-Api-Key': RADARR_API_KEY},
            timeout=30
        )
        response.raise_for_status()
        movies = response.json()

        # Return dict: tmdbId -> movie data
        return {m['tmdbId']: m for m in movies}

    except Exception as e:
        log(f"Error fetching Radarr movies: {e}")
        return {}


def get_sonarr_series():
    """Get all series in Sonarr"""
    try:
        response = requests.get(
            f'{SONARR_URL}/api/v3/series',
            headers={'X-Api-Key': SONARR_API_KEY},
            timeout=30
        )
        response.raise_for_status()
        series = response.json()

        # Return dict: tvdbId -> series data
        return {s['tvdbId']: s for s in series}

    except Exception as e:
        log(f"Error fetching Sonarr series: {e}")
        return {}


def delete_from_radarr(movie_id, movie_title, delete_files=True):
    """Delete a movie from Radarr"""
    try:
        if DRY_RUN:
            log(f"  [DRY RUN] Would delete from Radarr: {movie_title}")
            return True

        response = requests.delete(
            f'{RADARR_URL}/api/v3/movie/{movie_id}',
            headers={'X-Api-Key': RADARR_API_KEY},
            params={'deleteFiles': delete_files, 'addImportExclusion': False},
            timeout=30
        )

        if response.status_code in [200, 204]:
            log(f"  Deleted from Radarr: {movie_title}")
            return True
        else:
            log(f"  Failed to delete from Radarr: {movie_title} - {response.status_code}")
            return False

    except Exception as e:
        log(f"  Error deleting from Radarr: {e}")
        return False


def delete_from_sonarr(series_id, series_title, delete_files=True):
    """Delete a series from Sonarr"""
    try:
        if DRY_RUN:
            log(f"  [DRY RUN] Would delete from Sonarr: {series_title}")
            return True

        response = requests.delete(
            f'{SONARR_URL}/api/v3/series/{series_id}',
            headers={'X-Api-Key': SONARR_API_KEY},
            params={'deleteFiles': delete_files, 'addImportListExclusion': False},
            timeout=30
        )

        if response.status_code in [200, 204]:
            log(f"  Deleted from Sonarr: {series_title}")
            return True
        else:
            log(f"  Failed to delete from Sonarr: {series_title} - {response.status_code}")
            return False

    except Exception as e:
        log(f"  Error deleting from Sonarr: {e}")
        return False


def cleanup_qbittorrent_orphans():
    """Remove completed torrents that are no longer needed"""
    try:
        # Get all completed torrents
        response = requests.get(
            f'{QBITTORRENT_URL}/api/v2/torrents/info',
            params={'filter': 'completed'},
            timeout=30
        )

        if response.status_code != 200:
            log(f"Failed to fetch qBittorrent torrents: {response.status_code}")
            return

        torrents = response.json()
        orphan_count = 0

        for torrent in torrents:
            save_path = torrent.get('save_path', '')
            content_path = torrent.get('content_path', '')
            name = torrent.get('name', 'Unknown')
            torrent_hash = torrent.get('hash', '')

            # Check if the download location still exists
            # If Radarr/Sonarr deleted the files, we can remove the torrent
            if content_path and not os.path.exists(content_path):
                if DRY_RUN:
                    log(f"  [DRY RUN] Would remove orphan torrent: {name}")
                else:
                    # Remove torrent (files already gone)
                    del_response = requests.post(
                        f'{QBITTORRENT_URL}/api/v2/torrents/delete',
                        data={'hashes': torrent_hash, 'deleteFiles': 'false'},
                        timeout=30
                    )
                    if del_response.status_code == 200:
                        log(f"  Removed orphan torrent: {name}")
                        orphan_count += 1

        if orphan_count > 0:
            log(f"Cleaned up {orphan_count} orphan torrent(s) from qBittorrent")

    except Exception as e:
        log(f"Error cleaning qBittorrent: {e}")


def main():
    log("=" * 60)
    log("Media Cleanup - Jellyseerr as Source of Truth")
    log("=" * 60)

    if DRY_RUN:
        log("MODE: DRY RUN (no actual deletions)")
    else:
        log("MODE: LIVE (will delete orphaned media)")

    # Get what Jellyseerr is tracking
    jellyseerr_media = get_jellyseerr_media()

    if not jellyseerr_media['movies'] and not jellyseerr_media['tv']:
        log("WARNING: No media found in Jellyseerr. Aborting to prevent accidental deletion.")
        return

    # Get what Radarr/Sonarr have
    radarr_movies = get_radarr_movies()
    sonarr_series = get_sonarr_series()

    log(f"Radarr has: {len(radarr_movies)} movies")
    log(f"Sonarr has: {len(sonarr_series)} TV shows")

    # Find orphans in Radarr (not in Jellyseerr)
    orphan_movies = []
    for tmdb_id, movie in radarr_movies.items():
        if tmdb_id not in jellyseerr_media['movies']:
            orphan_movies.append(movie)

    # Find orphans in Sonarr (not in Jellyseerr)
    orphan_series = []
    for tvdb_id, series in sonarr_series.items():
        if tvdb_id not in jellyseerr_media['tv']:
            orphan_series.append(series)

    log("")
    log(f"Found {len(orphan_movies)} orphan movie(s) in Radarr")
    log(f"Found {len(orphan_series)} orphan TV show(s) in Sonarr")

    # Delete orphan movies
    if orphan_movies:
        log("")
        log("Cleaning orphan movies from Radarr...")
        for movie in orphan_movies:
            delete_from_radarr(movie['id'], movie['title'])

    # Delete orphan series
    if orphan_series:
        log("")
        log("Cleaning orphan TV shows from Sonarr...")
        for series in orphan_series:
            delete_from_sonarr(series['id'], series['title'])

    # Clean up orphan torrents
    log("")
    log("Checking for orphan torrents in qBittorrent...")
    cleanup_qbittorrent_orphans()

    log("")
    log("Cleanup complete!")
    log("=" * 60)


if __name__ == '__main__':
    main()
