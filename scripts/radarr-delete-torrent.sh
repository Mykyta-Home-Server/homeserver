#!/bin/bash
# Radarr Custom Script - Delete torrent from qBittorrent on movie delete
# Triggered via Radarr → Settings → Connect → Custom Script
#
# Environment variables provided by Radarr:
# - radarr_eventtype: MovieDelete
# - radarr_movie_title: Movie title
# - radarr_movie_path: Path to movie folder

QBITTORRENT_URL="${QBITTORRENT_URL:-http://qbittorrent:8080}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Only run on delete events
if [ "$radarr_eventtype" != "MovieDelete" ]; then
    log "Event type: $radarr_eventtype (not MovieDelete, skipping)"
    exit 0
fi

log "Movie deleted: $radarr_movie_title"
log "Path: $radarr_movie_path"

# Extract just the movie name (without year) for more flexible matching
# "Forrest Gump (1994)" -> "Forrest Gump"
MOVIE_NAME=$(echo "$radarr_movie_title" | sed 's/ ([0-9]\{4\})$//')
log "Looking for torrents matching: $MOVIE_NAME"

# Get all torrents from qBittorrent (as JSON)
TORRENTS=$(curl -s "${QBITTORRENT_URL}/api/v2/torrents/info" 2>/dev/null)

if [ -z "$TORRENTS" ] || [ "$TORRENTS" = "[]" ]; then
    log "No torrents found or failed to connect to qBittorrent"
    exit 0
fi

# Parse with jq and match by movie name
echo "$TORRENTS" | jq -r '.[] | "\(.hash)|\(.name)"' | while IFS='|' read -r hash name; do
    # Case-insensitive match on movie name
    if echo "$name" | grep -iq "^${MOVIE_NAME}"; then
        log "Found matching torrent: $name"
        log "Hash: $hash"

        # Delete torrent with files
        RESULT=$(curl -s -X POST "${QBITTORRENT_URL}/api/v2/torrents/delete" \
            -d "hashes=${hash}&deleteFiles=true" 2>/dev/null)

        log "Deleted torrent and files"
    fi
done

log "Cleanup complete"
