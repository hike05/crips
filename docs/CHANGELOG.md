# Changelog

All notable changes to Crips will be documented in this file.

## [1.0.0] - 2025-11-26

### Added
- Initial release
- Custom Caddy build with essential plugins
- Automated installation script with interactive prompts
- CrowdSec integration with auto-generated bouncer keys
- Optional REALITY protocol support via Sing-box
- Docker Compose orchestration with profiles
- Automatic HTTPS with Let's Encrypt
- HTTP/3 support
- Layer 4 SNI routing for REALITY mode
- Comprehensive documentation
- Production-ready configuration

### Features
- **Basic Mode**: Forward proxy with CrowdSec protection
- **REALITY Mode**: Advanced protocol camouflage
- One-command installation
- Auto-generated CrowdSec bouncer API keys
- Auto-generated REALITY keys
- Rate limiting (100 requests/minute per IP)
- JSON access logging
- TLS 1.2/1.3 support
- Automatic HTTP to HTTPS redirect
- Health checks for all services

### Documentation
- README with overview and quick start
- Deployment guide with manual and automated setup
- Architecture documentation with diagrams
- Contributing guidelines
- Changelog

### Components
- Caddy with forward_proxy, crowdsec-bouncer, layer4, rate_limit
- CrowdSec for threat protection
- Sing-box for REALITY protocol
- Docker Compose for orchestration
