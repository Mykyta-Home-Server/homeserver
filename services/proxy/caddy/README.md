# Caddy Reverse Proxy Configuration

This directory contains the modular Caddy configuration for your home server.

## Directory Structure

```
/opt/homeserver/services/caddy/
├── Caddyfile              # Master configuration file
├── sites/                 # Individual service configurations
│   ├── _template.caddy   # Template for new services
│   └── hello-world.caddy # Example service configuration
├── certs/                 # Cloudflare Origin Certificates
│   ├── origin.pem        # Certificate (valid until 2040)
│   └── origin.key        # Private key
├── data/                  # Caddy persistent data (auto-generated)
└── config/                # Caddy runtime config (auto-generated)
```

## Quick Start: Adding a New Service

### 1. Copy the template
```bash
cp sites/_template.caddy sites/your-service.caddy
```

### 2. Edit the configuration
```bash
nano sites/your-service.caddy
```

Replace placeholders:
- `subdomain` → your actual subdomain
- `container-name` → your Docker container name
- `PORT` → internal port your service uses

### 3. Set permissions
```bash
chmod 644 sites/your-service.caddy
```

### 4. Reload Caddy
```bash
docker compose restart caddy
```

### 5. Verify it's working
```bash
# Check Caddy loaded the config
docker compose logs caddy | grep -i "your-service"

# Test internal connectivity
docker exec caddy curl -I http://your-service:PORT

# Test external access
curl -I https://subdomain.mykyta-ryasny.dev
```

## Master Caddyfile Explanation

The master `Caddyfile` contains:

### Global Options
```caddy
{
    auto_https off  # We manually configure HTTPS with Cloudflare certs
}
```

### Reusable Snippets
```caddy
(cf_tls) {
    tls /etc/caddy/certs/origin.pem /etc/caddy/certs/origin.key
}
```

Use this snippet in all your service configs with: `import cf_tls`

### Import Statement
```caddy
import sites/*.caddy
```

Automatically loads all `.caddy` files from the `sites/` directory.

## Service Configuration Template

Basic structure for `sites/your-service.caddy`:

```caddy
# Service description and metadata
https://subdomain.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy container-name:PORT
}
```

## Common Patterns

### Simple Reverse Proxy
```caddy
https://plex.mykyta-ryasny.dev {
    import cf_tls
    reverse_proxy plex:32400
}
```

### With Custom Headers
```caddy
https://jellyfin.mykyta-ryasny.dev {
    import cf_tls

    header {
        X-Forwarded-Proto https
    }

    reverse_proxy jellyfin:8096
}
```

### With WebSocket Support
```caddy
https://console.mykyta-ryasny.dev {
    import cf_tls

    reverse_proxy minecraft:8080 {
        header_up Upgrade {http.request.header.Upgrade}
        header_up Connection {http.request.header.Connection}
    }
}
```

### WWW Redirect
```caddy
https://www.mykyta-ryasny.dev {
    import cf_tls
    redir https://mykyta-ryasny.dev{uri}
}
```

## Troubleshooting

### Config not loading?
```bash
# Check for syntax errors
docker compose logs caddy | grep -i error

# Verify files are readable
ls -lah sites/

# Recreate container if needed
docker compose up -d --force-recreate caddy
```

### Can't reach service?
```bash
# Test internal connectivity
docker exec caddy curl -I http://container-name:PORT

# Check if container is on web network
docker inspect container-name | grep -A 5 Networks
```

### Certificate issues?
```bash
# Verify certs are mounted
docker exec caddy ls -lah /etc/caddy/certs/

# Check Cloudflare SSL mode is "Full"
```

## Important Notes

1. **Always use the `cf_tls` snippet** for HTTPS sites
2. **File permissions must be 644** for Caddy to read them
3. **Container must be on `web` network** to be accessible
4. **Don't edit the master Caddyfile** unless adding global config
5. **One service per file** keeps things organized

## Additional Resources

- Full documentation: `/opt/homeserver/.claude/docs/adding-services.md`
- Template file: `sites/_template.caddy`
- Caddy documentation: https://caddyserver.com/docs/
- Cloudflare Tunnel docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

## Current Services

- **hello-world** - Main website at mykyta-ryasny.dev
  - Config: `sites/hello-world.caddy`
  - Container: hello-world (nginx:alpine)
  - Port: 80

---

**Last Updated**: November 22, 2025
