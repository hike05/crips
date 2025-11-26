# Architecture

## Overview

Crips is a modular proxy stack that can operate in two modes:

1. **Basic Mode** - Standard forward proxy with threat protection
2. **REALITY Mode** - Advanced mode with protocol camouflage

## Basic Mode Architecture

```
┌─────────────────────┐
│      Internet       │
└─────────┬───────────┘
          │ 443
          ▼
┌─────────────────────┐
│   Caddy:443         │
│   (TLS + HTTP/3)    │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ CrowdSec Bouncer    │
│ (IP Reputation)     │
└─────────┬───────────┘
          │
     ┌────┴────┐
     │ Blocked │ → 403 Forbidden
     └─────────┘
          │ Allowed
          ▼
┌─────────────────────┐
│  Forward Proxy      │
│  (Basic Auth)       │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Rate Limiter      │
│   (100 req/min)     │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Upstream          │
│   Internet          │
└─────────────────────┘
```

## REALITY Mode Architecture

```
┌─────────────────────┐
│      Internet       │
└─────────┬───────────┘
          │ 443
          ▼
┌─────────────────────┐
│  Caddy Layer4:443   │
│  (TLS + SNI)        │
└─────────┬───────────┘
          │
          │ SNI Routing
          │
    ┌─────┴─────────────────────────┐
    │                               │
    ▼                               ▼
┌───────────────────┐    ┌──────────────────┐
│ SNI = REALITY     │    │ Other SNI        │
│ Domain            │    │                  │
│                   │    │                  │
│ Passthrough TCP   │    │ TLS Termination  │
│ → Sing-box:443    │    │ → Caddy:8443     │
└───────┬───────────┘    └────────┬─────────┘
        │                         │
        ▼                         ▼
┌───────────────────┐    ┌──────────────────┐
│ Sing-box          │    │ CrowdSec         │
│ REALITY Protocol  │    │ → Forward Proxy  │
│ VLESS + Vision    │    │ → Rate Limiter   │
└───────┬───────────┘    └────────┬─────────┘
        │                         │
        ▼                         ▼
┌───────────────────┐    ┌──────────────────┐
│   Upstream        │    │   Upstream       │
│   Internet        │    │   Internet       │
└───────────────────┘    └──────────────────┘
```

## Components

### Caddy
- **Image**: `ghcr.io/hike05/crips:latest`
- **Plugins**:
  - `forward_proxy` - HTTP/HTTPS proxy
  - `caddy-crowdsec-bouncer` - CrowdSec integration
  - `caddy-l4` - Layer 4 proxy for SNI routing
  - `rate_limit` - Request rate limiting
- **Ports**: 
  - 80/tcp - HTTP redirect
  - 443/tcp - HTTPS/Layer4
  - 443/udp - HTTP/3
  - 8443/tcp - Internal HTTP server (REALITY mode)

### CrowdSec
- **Image**: `crowdsecurity/crowdsec:latest`
- **Purpose**: Real-time threat detection and IP reputation
- **API**: Local API (LAPI) on port 8080
- **Database**: SQLite in `/var/lib/crowdsec/data`

### Sing-box (REALITY mode only)
- **Image**: `ghcr.io/sagernet/sing-box:latest`
- **Protocol**: VLESS with REALITY
- **Purpose**: Protocol camouflage via TLS fingerprint mimicry
- **Port**: 443/tcp (internal)

## Network Flow

### Basic Mode

1. **Client** connects to `https://domain.com:443`
2. **Caddy** terminates TLS, validates certificate
3. **CrowdSec Bouncer** queries LAPI for IP reputation
4. **Forward Proxy** validates basic auth credentials
5. **Rate Limiter** checks request rate
6. **Upstream** request forwarded to destination
7. **Logging** access recorded in JSON format

### REALITY Mode

#### REALITY Traffic
1. **Client** connects to `https://reality-domain.com:443`
2. **Caddy Layer4** inspects SNI
3. **SNI matches** REALITY_DOMAIN → passthrough to Sing-box
4. **Sing-box** handles REALITY handshake
5. **VLESS** protocol decrypts and forwards traffic
6. **Upstream** request forwarded to destination

#### Regular Traffic
1. **Client** connects to `https://domain.com:443`
2. **Caddy Layer4** inspects SNI
3. **SNI doesn't match** → proxy to Caddy:8443
4. **Caddy** terminates TLS internally
5. **CrowdSec** → **Forward Proxy** → **Rate Limiter**
6. **Upstream** request forwarded to destination

## Data Persistence

### Volumes

- `caddy_data` - Caddy data (certificates, etc.)
- `caddy_config` - Caddy configuration cache
- `crowdsec_config` - CrowdSec configuration
- `crowdsec_data` - CrowdSec database and decisions
- `/var/log/crips` - Access logs

### Important Files

- `.env` - Environment configuration (secrets)
- `Caddyfile` - Caddy server configuration
- `singbox-config.json` - Sing-box configuration
- `crowdsec_data/crowdsec.db` - CrowdSec SQLite database

## Security Model

### Defense Layers

1. **Network**: Firewall (ports 80, 443 only)
2. **Application**: CrowdSec IP filtering
3. **Authentication**: Basic auth for proxy
4. **Rate Limiting**: Per-IP throttling
5. **TLS**: Modern cipher suites (TLS 1.2+)
6. **Protocol**: REALITY camouflage (optional)

### Threat Protection

- **Brute Force**: CrowdSec detection and blocking
- **DDoS**: Rate limiting + CrowdSec scenarios
- **Scanning**: Automated threat detection
- **Known Threats**: CrowdSec community blocklists
- **DPI**: REALITY protocol mimics legitimate TLS

## Configuration

### Environment Variables

All configuration via `.env`:

**Required:**
- `DOMAIN` - Public domain
- `EMAIL` - Let's Encrypt contact
- `PROXY_USER` - Proxy username
- `PROXY_PASS` - Proxy password
- `BOUNCER_KEY` - CrowdSec API key

**Optional (REALITY):**
- `ENABLE_REALITY` - Enable REALITY mode
- `REALITY_DOMAIN` - REALITY SNI domain
- `REALITY_UUID` - Client UUID
- `REALITY_SERVER_NAME` - Target server
- `REALITY_DEST` - Handshake destination
- `REALITY_PRIVATE_KEY` - Server private key
- `REALITY_SHORT_ID` - Routing short ID

### Docker Compose Profiles

- `basic` - Caddy + CrowdSec only
- `reality` - Caddy + CrowdSec + Sing-box

## Monitoring

### Health Checks

- **CrowdSec**: `cscli version` every 10s
- **Caddy**: Depends on CrowdSec health

### Metrics

- Caddy metrics: `localhost:2019/metrics`
- CrowdSec metrics: `cscli metrics`

### Logs

- **Access**: `/var/log/crips/access.log` (JSON)
- **Caddy**: `docker compose logs caddy`
- **CrowdSec**: `docker compose logs crowdsec`
- **Sing-box**: `docker compose logs singbox`

## Scalability

### Horizontal Scaling

1. Deploy multiple instances
2. Share CrowdSec LAPI endpoint
3. Use same `BOUNCER_KEY`
4. Load balancer in front

### Vertical Scaling

Add resource limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

## Backup Strategy

### Critical Data

1. **CrowdSec Database**: `crowdsec_data/crowdsec.db`
2. **Configuration**: `.env`, `Caddyfile`, `singbox-config.json`
3. **Certificates**: `caddy_data` volume (auto-renewed)

### Backup Command

```bash
tar -czf crips-backup-$(date +%Y%m%d).tar.gz \
  .env Caddyfile singbox-config.json
docker run --rm -v crips_crowdsec_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/crowdsec-data.tar.gz -C /data .
```

## Component Licenses

- [Caddy](https://github.com/caddyserver/caddy) - Apache 2.0
- [CrowdSec](https://github.com/crowdsecurity/crowdsec) - MIT
- [Sing-box](https://github.com/SagerNet/sing-box) - GPLv3
- [forward_proxy](https://github.com/caddyserver/forwardproxy) - Apache 2.0
- [caddy-crowdsec-bouncer](https://github.com/hslatman/caddy-crowdsec-bouncer) - MIT
