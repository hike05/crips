# Caddy Build

Custom Caddy build with plugins for Crips proxy stack.

## Included Plugins

- **forwardproxy** - HTTP/HTTPS forward proxy with authentication
- **caddy-crowdsec-bouncer** - CrowdSec integration for threat protection
- **caddy-l4** - Layer 4 proxy for SNI routing
- **caddy-ratelimit** - Request rate limiting

## Building

```bash
docker build -t ghcr.io/hike05/crips:latest .
```

## Automated Builds

GitHub Actions automatically builds and publishes new images when:
- Caddy releases a new version
- Plugin updates are available
- Manual workflow trigger

See `.github/workflows/build-caddy.yml` for CI/CD configuration.

## Base Image

Built on official Caddy image with xcaddy for plugin compilation.

## Updates

This build is updated regularly to include:
- Latest Caddy stable release
- Latest plugin versions
- Security patches
- Chromium network stack updates (for forward_proxy)
