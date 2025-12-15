#!/usr/bin/env python3
"""
Docker Image Update Checker
Checks for newer versions of pinned Docker images and logs results to stdout.
Logs are collected by Promtail → Loki → Grafana for monitoring.
"""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import urllib.request
import urllib.error

# ANSI color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def log_json(level: str, message: str, **kwargs):
    """Log structured JSON for Loki ingestion"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "level": level.upper(),
        "script": "check-updates",
        "message": message,
        **kwargs
    }
    print(json.dumps(log_entry), flush=True)

def log_human(level: str, message: str, color: str = Colors.RESET):
    """Log human-readable format"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{color}[{timestamp}] [{level.upper()}] {message}{Colors.RESET}", flush=True)

def parse_compose_files(compose_dir: Path) -> Dict[str, str]:
    """
    Parse all compose files and extract image specifications.
    Returns: {image_name: current_version}
    """
    images = {}
    image_pattern = re.compile(r'image:\s+([^:\s]+):([^\s]+)')

    for compose_file in compose_dir.rglob("*.yml"):
        try:
            with open(compose_file, 'r') as f:
                for line in f:
                    match = image_pattern.search(line)
                    if match:
                        image_name = match.group(1)
                        version = match.group(2)
                        # Skip portal (our own image)
                        if "homeserver-portal" not in image_name:
                            images[image_name] = version
        except Exception as e:
            log_json("warning", f"Failed to parse {compose_file.name}", error=str(e))

    return images

def get_registry_api_url(image: str) -> tuple[str, str, str]:
    """
    Determine registry API URL based on image source.
    Returns: (registry_url, namespace, image_name)
    """
    if image.startswith("ghcr.io/"):
        # GitHub Container Registry
        parts = image.replace("ghcr.io/", "").split("/")
        if len(parts) == 2:
            return ("https://ghcr.io", parts[0], parts[1])
    elif image.startswith("lscr.io/"):
        # LinuxServer.io registry
        parts = image.replace("lscr.io/", "").split("/")
        if len(parts) == 2:
            return ("https://lscr.io", parts[0], parts[1])
    elif "/" in image:
        # Docker Hub with namespace
        parts = image.split("/")
        if len(parts) == 2:
            return ("https://registry.hub.docker.com", parts[0], parts[1])
    else:
        # Docker Hub official image
        return ("https://registry.hub.docker.com", "library", image)

    return ("", "", "")

def get_docker_hub_token(namespace: str, image: str) -> Optional[str]:
    """Get authentication token for Docker Hub API"""
    try:
        token_url = f"https://auth.docker.io/token?service=registry.docker.io&scope=repository:{namespace}/{image}:pull"
        with urllib.request.urlopen(token_url, timeout=10) as response:
            data = json.loads(response.read())
            return data.get("token")
    except Exception as e:
        log_json("debug", f"Failed to get Docker Hub token", image=f"{namespace}/{image}", error=str(e))
        return None

def get_available_tags_dockerhub(namespace: str, image: str) -> List[str]:
    """Get available tags from Docker Hub"""
    try:
        token = get_docker_hub_token(namespace, image)
        if not token:
            return []

        url = f"https://registry.hub.docker.com/v2/{namespace}/{image}/tags/list"
        req = urllib.request.Request(url)
        req.add_header("Authorization", f"Bearer {token}")

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read())
            return data.get("tags", [])
    except Exception as e:
        log_json("debug", f"Failed to fetch Docker Hub tags", image=f"{namespace}/{image}", error=str(e))
        return []

def get_available_tags_ghcr(namespace: str, image: str) -> List[str]:
    """Get available tags from GitHub Container Registry"""
    try:
        # GHCR uses OCI distribution spec
        url = f"https://ghcr.io/v2/{namespace}/{image}/tags/list"
        req = urllib.request.Request(url)

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read())
            return data.get("tags", [])
    except urllib.error.HTTPError as e:
        if e.code == 401:
            log_json("debug", "GHCR authentication required (skipping)", image=f"{namespace}/{image}")
        else:
            log_json("debug", f"Failed to fetch GHCR tags", image=f"{namespace}/{image}", error=str(e))
        return []
    except Exception as e:
        log_json("debug", f"Failed to fetch GHCR tags", image=f"{namespace}/{image}", error=str(e))
        return []

def get_available_tags_lscr(namespace: str, image: str) -> List[str]:
    """Get available tags from LinuxServer.io registry"""
    try:
        # LSCR also uses OCI distribution spec
        url = f"https://lscr.io/v2/{namespace}/{image}/tags/list"
        req = urllib.request.Request(url)

        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read())
            return data.get("tags", [])
    except Exception as e:
        log_json("debug", f"Failed to fetch LSCR tags", image=f"{namespace}/{image}", error=str(e))
        return []

def get_latest_tag(image: str, current_version: str) -> Optional[str]:
    """
    Get the latest available tag for an image.
    Returns None if cannot determine or if already on latest.
    """
    registry_url, namespace, image_name = get_registry_api_url(image)

    if not registry_url:
        log_json("debug", "Cannot determine registry", image=image)
        return None

    # Get available tags based on registry
    if "ghcr.io" in registry_url:
        tags = get_available_tags_ghcr(namespace, image_name)
    elif "lscr.io" in registry_url:
        tags = get_available_tags_lscr(namespace, image_name)
    else:
        tags = get_available_tags_dockerhub(namespace, image_name)

    if not tags:
        return None

    # Check if "latest" tag exists and is different from current
    if "latest" in tags:
        # For now, we can't determine the actual version of "latest" without pulling
        # So we'll just note that a "latest" tag exists
        return "latest"

    return None

def check_updates(compose_dir: Path, use_json: bool = True):
    """
    Main update checking logic.
    Parses compose files, checks for updates, and logs results.
    """
    if use_json:
        log_json("info", "Starting Docker image update check")
    else:
        log_human("info", f"{Colors.BOLD}Starting Docker Image Update Check{Colors.RESET}", Colors.BLUE)

    # Parse compose files
    images = parse_compose_files(compose_dir)

    if use_json:
        log_json("info", f"Found {len(images)} images to check")
    else:
        log_human("info", f"Found {len(images)} pinned images", Colors.BLUE)

    # Check each image
    updates_available = 0
    up_to_date = 0
    check_failed = 0

    for image, current_version in sorted(images.items()):
        if use_json:
            log_json("debug", "Checking image", image=image, current_version=current_version)
        else:
            log_human("info", f"Checking: {image}:{current_version}", Colors.BLUE)

        # For now, we'll use a simple heuristic:
        # If we can fetch tags and "latest" exists, suggest checking it
        registry_url, namespace, image_name = get_registry_api_url(image)

        if not registry_url:
            check_failed += 1
            if use_json:
                log_json("warning", "Cannot determine registry", image=image)
            else:
                log_human("warning", f"  ⚠️  Cannot determine registry for {image}", Colors.YELLOW)
            continue

        # Get available tags
        if "ghcr.io" in registry_url:
            tags = get_available_tags_ghcr(namespace, image_name)
        elif "lscr.io" in registry_url:
            tags = get_available_tags_lscr(namespace, image_name)
        else:
            tags = get_available_tags_dockerhub(namespace, image_name)

        if not tags:
            check_failed += 1
            if use_json:
                log_json("warning", "Failed to fetch tags", image=image)
            else:
                log_human("warning", f"  ⚠️  Failed to fetch tags for {image}", Colors.YELLOW)
            continue

        # Check if current version is still in available tags
        if current_version not in tags:
            updates_available += 1
            if use_json:
                log_json("warning", "Version not found in registry (possibly outdated)",
                        image=image, current_version=current_version, update_available=True)
            else:
                log_human("warning", f"  ⚠️  Version {current_version} not found in registry - may be outdated!", Colors.YELLOW)
        else:
            # Check if there are newer-looking tags (this is heuristic)
            # For LinuxServer images, check for higher -ls numbers
            if "-ls" in current_version:
                current_ls = int(re.search(r'-ls(\d+)', current_version).group(1))
                latest_ls = max([int(re.search(r'-ls(\d+)', t).group(1))
                               for t in tags if re.search(r'-ls(\d+)', t)], default=current_ls)

                if latest_ls > current_ls:
                    updates_available += 1
                    newer_tag = [t for t in tags if f"-ls{latest_ls}" in t][0]
                    if use_json:
                        log_json("info", "Update available", image=image,
                                current_version=current_version, latest_version=newer_tag,
                                update_available=True)
                    else:
                        log_human("info", f"  ✨ Update available: {newer_tag}", Colors.GREEN)
                else:
                    up_to_date += 1
                    if use_json:
                        log_json("info", "Up to date", image=image, current_version=current_version,
                                update_available=False)
                    else:
                        log_human("info", f"  ✓ Up to date", Colors.GREEN)
            else:
                # For other images, just note that we found the version
                up_to_date += 1
                if use_json:
                    log_json("info", "Version found in registry", image=image,
                            current_version=current_version, update_available=False)
                else:
                    log_human("info", f"  ✓ Version found in registry", Colors.GREEN)

    # Summary
    if use_json:
        log_json("info", "Update check complete",
                total=len(images), updates_available=updates_available,
                up_to_date=up_to_date, check_failed=check_failed)
    else:
        log_human("info", f"\n{Colors.BOLD}Summary:{Colors.RESET}", Colors.BLUE)
        log_human("info", f"  Total images: {len(images)}", Colors.BLUE)
        log_human("info", f"  Updates available: {updates_available}", Colors.YELLOW if updates_available > 0 else Colors.GREEN)
        log_human("info", f"  Up to date: {up_to_date}", Colors.GREEN)
        log_human("info", f"  Check failed: {check_failed}", Colors.RED if check_failed > 0 else Colors.GREEN)

def main():
    """Main entry point"""
    # Determine compose directory
    compose_dir = Path("/opt/homeserver/compose")
    if not compose_dir.exists():
        # Try relative path (for local testing)
        compose_dir = Path(__file__).parent.parent / "compose"

    if not compose_dir.exists():
        print(json.dumps({
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": "ERROR",
            "script": "check-updates",
            "message": "Compose directory not found",
            "path": str(compose_dir)
        }), flush=True)
        sys.exit(1)

    # Check if running in Docker (use JSON) or terminal (use human-readable)
    use_json = not sys.stdout.isatty()

    try:
        check_updates(compose_dir, use_json=use_json)
    except Exception as e:
        if use_json:
            log_json("error", "Update check failed", error=str(e))
        else:
            log_human("error", f"Update check failed: {e}", Colors.RED)
        sys.exit(1)

if __name__ == "__main__":
    main()
