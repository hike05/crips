## What is Crips?

Crips combines battle-tested open-source components into a secure, easy-to-deploy proxy solution:

- **Caddy** - Modern web server with automatic HTTPS and HTTP/3
- **CrowdSec** - Collaborative threat intelligence and IP reputation
- **Sing-box** - High-performance proxy with REALITY protocol (optional)
- **Forward Proxy** - Standard HTTPS proxy with authentication

## Features

- 🚀 One-command installation
- 🔒 Automatic HTTPS with Let's Encrypt
- 🛡️ Real-time threat protection via CrowdSec
- 🌐 HTTP/3 support
- 📊 Rate limiting and access logging
- 🎭 Optional REALITY protocol for advanced use cases
- 🐳 Docker-based deployment

## Quick Start

```bash
git clone https://github.com/hike05/crips.git
cd crips/deployment
./install.sh
```

The installer will guide you through configuration options.

## Architecture

### Basic Mode (Forward Proxy)
```
Internet → Caddy:443 → CrowdSec → Forward Proxy → Upstream
```

### REALITY Mode (Advanced)
```
Internet → Caddy Layer4:443 → SNI Routing
                              ├─ REALITY domain → Sing-box
                              └─ Other domains → Forward Proxy + CrowdSec
```

## Documentation

- [Installation Guide](deployment/README.md)
- [Architecture Details](docs/ARCHITECTURE.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Changelog](docs/CHANGELOG.md)

## Components

### Caddy Build
Custom Caddy build with essential plugins:
- `forward_proxy` - HTTP/HTTPS proxy functionality
- `caddy-crowdsec-bouncer` - CrowdSec integration
- `caddy-layer4` - Layer 4 proxy for SNI routing
- `rate_limit` - Request rate limiting

See [caddy-build/README.md](caddy-build/README.md) for build details.

### Deployment
Ready-to-use Docker Compose stack with automated setup.
See [deployment/README.md](deployment/README.md) for deployment guide.

## Requirements

- Linux server with public IP
- Docker and Docker Compose
- Domain name with DNS configured
- Ports 80 and 443 available

## License

This project integrates multiple open-source components. See individual component licenses:
- [Caddy](https://github.com/caddyserver/caddy) - Apache 2.0
- [CrowdSec](https://github.com/crowdsecurity/crowdsec) - MIT
- [Sing-box](https://github.com/SagerNet/sing-box) - GPLv3

## Credits

Built with:
- [Caddy](https://caddyserver.com/) by Matt Holt and contributors
- [CrowdSec](https://www.crowdsec.net/) by CrowdSec team
- [Sing-box](https://sing-box.sagernet.org/) by SagerNet
- [forward_proxy](https://github.com/caddyserver/forwardproxy) by Caddy team
- [caddy-crowdsec-bouncer](https://github.com/hslatman/caddy-crowdsec-bouncer) by Herman Slatman
