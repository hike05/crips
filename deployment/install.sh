#!/bin/bash
set -e

echo "================================"
echo "Crips Installer"
echo "================================"
echo ""

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Install: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found. Install: https://docs.docker.com/compose/install/"
    exit 1
fi

DOCKER_COMPOSE="docker compose"
if ! docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
fi

echo "✅ Docker environment validated"
echo ""

read -p "Domain (e.g., proxy.example.com): " DOMAIN
read -p "Email for Let's Encrypt: " EMAIL
read -p "Proxy username: " PROXY_USER
read -sp "Proxy password: " PROXY_PASS
echo ""
echo ""

read -p "Enable REALITY protocol? (y/n): " ENABLE_REALITY_INPUT
ENABLE_REALITY="false"
COMPOSE_PROFILE="basic"

if [[ "$ENABLE_REALITY_INPUT" =~ ^[Yy]$ ]]; then
    ENABLE_REALITY="true"
    COMPOSE_PROFILE="reality"
    echo ""
    echo "REALITY Configuration:"
    read -p "REALITY domain (e.g., r1.example.com): " REALITY_DOMAIN
    read -p "REALITY server name (e.g., www.microsoft.com): " REALITY_SERVER_NAME
    REALITY_DEST="${REALITY_SERVER_NAME}:443"
    
    echo ""
    echo "Generating REALITY keys..."
    REALITY_UUID=$(docker run --rm ghcr.io/sagernet/sing-box:latest generate uuid 2>/dev/null || echo "")
    REALITY_KEYPAIR=$(docker run --rm ghcr.io/sagernet/sing-box:latest generate reality-keypair 2>/dev/null || echo "")
    REALITY_PRIVATE_KEY=$(echo "$REALITY_KEYPAIR" | grep "PrivateKey:" | awk '{print $2}')
    REALITY_SHORT_ID=$(openssl rand -hex 8 2>/dev/null || echo "")
    
    if [ -z "$REALITY_UUID" ] || [ -z "$REALITY_PRIVATE_KEY" ] || [ -z "$REALITY_SHORT_ID" ]; then
        echo "⚠️  Failed to generate REALITY keys automatically."
        echo "Please generate manually:"
        echo "  UUID: docker run --rm ghcr.io/sagernet/sing-box:latest generate uuid"
        echo "  Keys: docker run --rm ghcr.io/sagernet/sing-box:latest generate reality-keypair"
        echo "  Short ID: openssl rand -hex 8"
        exit 1
    fi
    
    echo "✅ REALITY keys generated"
else
    REALITY_DOMAIN=""
    REALITY_UUID=""
    REALITY_SERVER_NAME=""
    REALITY_DEST=""
    REALITY_PRIVATE_KEY=""
    REALITY_SHORT_ID=""
fi

echo ""
echo "📝 Generating configuration..."
cat > .env << EOF
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
PROXY_USER=${PROXY_USER}
PROXY_PASS=${PROXY_PASS}
BOUNCER_KEY=
ENABLE_REALITY=${ENABLE_REALITY}
REALITY_DOMAIN=${REALITY_DOMAIN}
REALITY_UUID=${REALITY_UUID}
REALITY_SERVER_NAME=${REALITY_SERVER_NAME}
REALITY_DEST=${REALITY_DEST}
REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY}
REALITY_SHORT_ID=${REALITY_SHORT_ID}
EOF

echo "✅ Configuration saved to .env"
echo ""

echo "🚀 Deploying containers..."
COMPOSE_PROFILES=$COMPOSE_PROFILE $DOCKER_COMPOSE up -d

echo ""
echo "⏳ Waiting for CrowdSec..."

RETRY=0
MAX_RETRIES=30
until docker inspect crips-crowdsec --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; do
    if [ $RETRY -ge $MAX_RETRIES ]; then
        echo "❌ CrowdSec health check timeout"
        exit 1
    fi
    sleep 2
    RETRY=$((RETRY + 1))
done

echo "✅ CrowdSec ready"
sleep 3

echo "🔑 Generating bouncer API key..."

docker exec crips-crowdsec cscli bouncers delete crips-bouncer 2>/dev/null || true

BOUNCER_KEY_RAW=$(docker exec crips-crowdsec cscli bouncers add crips-bouncer -o raw 2>&1)

if echo "$BOUNCER_KEY_RAW" | grep -q "Error"; then
    BOUNCER_KEY=""
else
    BOUNCER_KEY=$(echo "$BOUNCER_KEY_RAW" | tr -d '%\n\r ' | head -c 100)
fi

if [ -z "$BOUNCER_KEY" ]; then
    echo "⚠️  Auto-generation failed. Manual steps:"
    echo "  docker exec crips-crowdsec cscli bouncers add crips-bouncer -o raw"
    echo "  Add key to .env: BOUNCER_KEY=<generated_key>"
    echo "  Restart: COMPOSE_PROFILES=$COMPOSE_PROFILE $DOCKER_COMPOSE restart caddy"
else
    BOUNCER_KEY_ESCAPED=$(echo "$BOUNCER_KEY" | sed 's/[\/&+]/\\&/g')
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/BOUNCER_KEY=.*/BOUNCER_KEY=${BOUNCER_KEY_ESCAPED}/" .env
    else
        sed -i "s/BOUNCER_KEY=.*/BOUNCER_KEY=${BOUNCER_KEY_ESCAPED}/" .env
    fi
    
    echo "✅ Bouncer key configured"
    echo ""
    
    echo "🔄 Restarting proxy..."
    COMPOSE_PROFILES=$COMPOSE_PROFILE $DOCKER_COMPOSE up -d caddy
    sleep 3
fi

echo ""
echo "================================"
echo "✅ Installation Complete"
echo "================================"
echo ""
echo "Services:"
COMPOSE_PROFILES=$COMPOSE_PROFILE $DOCKER_COMPOSE ps
echo ""
echo "Proxy endpoint: https://${DOMAIN}"
echo "Username: ${PROXY_USER}"

if [[ "$ENABLE_REALITY" == "true" ]]; then
    echo ""
    echo "REALITY endpoint: ${REALITY_DOMAIN}"
    echo "UUID: ${REALITY_UUID}"
fi

echo ""
echo "Verify bouncer:"
echo "  docker exec crips-crowdsec cscli bouncers list"
echo ""
echo "View logs:"
echo "  COMPOSE_PROFILES=$COMPOSE_PROFILE $DOCKER_COMPOSE logs -f"
echo ""
