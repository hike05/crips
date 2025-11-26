# Crips Deployment

Ready-to-use Docker Compose stack for Crips proxy.

## Quick Start

```bash
./install.sh
```

The installer will:
1. Validate Docker environment
2. Prompt for configuration (domain, credentials, etc.)
3. Ask if you want to enable REALITY protocol
4. Generate REALITY keys (if enabled)
5. Deploy containers
6. Auto-generate CrowdSec bouncer key
7. Start all services

## Manual Setup

### Basic Mode (Forward Proxy Only)

1. Copy and configure environment:
```bash
cp .env.example .env
nano .env
```

2. Deploy:
```bash
COMPOSE_PROFILES=basic docker compose up -d
```

3. Generate bouncer key:
```bash
docker exec crips-crowdsec cscli bouncers add crips-bouncer -o raw
```

4. Add key to `.env` and restart:
```bash
COMPOSE_PROFILES=basic docker compose restart caddy
```

### REALITY Mode

1. Configure environment with REALITY settings:
```bash
cp .env.example .env
nano .env
# Set ENABLE_REALITY=true and configure REALITY_* variables
```

2. Generate REALITY keys:
```bash
# UUID
docker run --rm ghcr.io/sagernet/sing-box:latest generate uuid

# Key pair
docker run --rm ghcr.io/sagernet/sing-box:latest generate reality-keypair

# Short ID
openssl rand -hex 8
```

3. Deploy:
```bash
COMPOSE_PROFILES=reality docker compose up -d
```

4. Generate bouncer key and restart as above.

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DOMAIN` | Yes | Your domain name |
| `EMAIL` | Yes | Let's Encrypt contact email |
| `PROXY_USER` | Yes | Forward proxy username |
| `PROXY_PASS` | Yes | Forward proxy password |
| `BOUNCER_KEY` | Yes | CrowdSec API key (auto-generated) |
| `ENABLE_REALITY` | No | Enable REALITY protocol (true/false) |
| `REALITY_DOMAIN` | If REALITY | Domain for REALITY inbound |
| `REALITY_UUID` | If REALITY | Client UUID |
| `REALITY_SERVER_NAME` | If REALITY | Target server for camouflage |
| `REALITY_DEST` | If REALITY | Handshake destination |
| `REALITY_PRIVATE_KEY` | If REALITY | Server private key |
| `REALITY_SHORT_ID` | If REALITY | Short ID for routing |

### Profiles

- `basic` - Forward proxy with CrowdSec only
- `reality` - Forward proxy + REALITY protocol

## Operations

### View Status
```bash
COMPOSE_PROFILES=basic docker compose ps
docker exec crips-crowdsec cscli bouncers list
```

### View Logs
```bash
COMPOSE_PROFILES=basic docker compose logs -f
docker compose logs -f caddy
docker compose logs -f crowdsec
```

### Update
```bash
COMPOSE_PROFILES=basic docker compose pull
COMPOSE_PROFILES=basic docker compose up -d
```

### Stop
```bash
COMPOSE_PROFILES=basic docker compose down
```

### Clean Restart
```bash
COMPOSE_PROFILES=basic docker compose down -v
./install.sh
```

## Client Configuration

### Forward Proxy

Configure your client to use HTTPS proxy:
- **Proxy**: `https://your-domain.com:443`
- **Username**: Your configured username
- **Password**: Your configured password

### REALITY (if enabled)

Use a VLESS client with REALITY support:
```json
{
  "server": "your-reality-domain.com",
  "server_port": 443,
  "uuid": "your-uuid",
  "flow": "xtls-rprx-vision",
  "tls": {
    "enabled": true,
    "server_name": "www.microsoft.com",
    "reality": {
      "enabled": true,
      "public_key": "your-public-key",
      "short_id": "your-short-id"
    }
  }
}
```

## Troubleshooting

**Services not starting:**
```bash
docker compose logs
```

**CrowdSec bouncer not connecting:**
- Check `BOUNCER_KEY` is set in `.env`
- Verify bouncer exists: `docker exec crips-crowdsec cscli bouncers list`
- Check logs: `docker compose logs caddy`

**REALITY not working:**
- Verify all REALITY_* variables are set
- Check singbox logs: `docker compose logs singbox`
- Ensure REALITY_DOMAIN DNS points to your server
- Test with VLESS client

**SSL certificate errors:**
- Ensure DNS is configured correctly
- Check email is valid (not example.com)
- Wait a few minutes for Let's Encrypt validation
- Check logs: `docker compose logs caddy`

## Security Notes

- Use strong passwords for `PROXY_PASS`
- Keep `BOUNCER_KEY` and REALITY keys secret
- Regularly update: `docker compose pull && docker compose up -d`
- Monitor CrowdSec decisions: `docker exec crips-crowdsec cscli decisions list`
- Set up log rotation for `/var/log/crips`
