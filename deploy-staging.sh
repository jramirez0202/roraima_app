#!/bin/bash
# ============================================
# Deploy to Staging - Roraima Delivery
# ============================================
# Este script hace deploy a staging usando Docker Compose

set -e  # Exit on error

echo "🚀 Starting Staging Deployment..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if .env.staging exists
if [ ! -f .env.staging ]; then
    echo -e "${RED}❌ ERROR: .env.staging not found${NC}"
    echo "Please create .env.staging with required credentials"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Stop current containers
echo -e "${YELLOW}📦 Stopping current containers...${NC}"
docker compose -f docker-compose.staging.yml down

# Build new images (without cache for full rebuild)
echo ""
echo -e "${YELLOW}🔨 Building Docker images...${NC}"
docker compose -f docker-compose.staging.yml build --no-cache

# Start containers
echo ""
echo -e "${YELLOW}🚀 Starting containers...${NC}"
docker compose -f docker-compose.staging.yml up -d

# Wait for database to be ready
echo ""
echo -e "${YELLOW}⏳ Waiting for database...${NC}"
sleep 10

# Run database migrations
echo ""
echo -e "${YELLOW}📊 Running database migrations...${NC}"
docker compose -f docker-compose.staging.yml exec -T web rails db:migrate

# Check container health
echo ""
echo -e "${YELLOW}🏥 Checking container health...${NC}"
sleep 5
docker compose -f docker-compose.staging.yml ps

echo ""
echo -e "${GREEN}✅ Staging deployment complete!${NC}"
echo ""
echo "📝 Access your app at: http://localhost:3001"
echo ""
echo "Useful commands:"
echo "  • View logs:      docker compose -f docker-compose.staging.yml logs -f"
echo "  • Rails console:  docker compose -f docker-compose.staging.yml exec web rails console"
echo "  • Stop:           docker compose -f docker-compose.staging.yml down"
echo "  • Restart:        docker compose -f docker-compose.staging.yml restart"
echo ""
