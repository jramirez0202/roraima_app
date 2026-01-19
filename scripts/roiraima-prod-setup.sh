#!/bin/bash

#################################################################
# ROIRAIMA PRODUCTION SETUP SCRIPT
# Configura Security Groups, Redis, S3 y variables de entorno
# Región: us-east-1
#################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
REGION="us-east-1"
ACCOUNT_ID="079485644506"
VPC_ID="vpc-0a5d50798a0fed12c"
EC2_INSTANCE_ID="i-0240a712e53471fd6"
EC2_PRIVATE_IP="172.31.28.176"
RDS_ENDPOINT="roiraima-prod-db.cqzass28iype.us-east-1.rds.amazonaws.com"
RDS_PORT="5432"
REDIS_NODE_TYPE="cache.t3.micro"
S3_BUCKET_PROD="roiraima-prod-deliveries"
S3_BUCKET_STAGING="roiraima-staging-deliveries"

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}  ROIRAIMA PRODUCTION INFRASTRUCTURE SETUP${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

#################################################################
# 1. CREAR/VALIDAR SECURITY GROUPS
#################################################################

echo -e "${YELLOW}[1/5] Configurando Security Groups...${NC}"

# Obtener SG existentes
RDS_SG_ID="sg-0c4e0badbd56e54c8"
EC2_SG=$(aws ec2 describe-instances \
  --instance-ids $EC2_INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo "  • RDS Security Group: $RDS_SG_ID"
echo "  • EC2 Security Group: $EC2_SG"

# Crear SG para Redis si no existe
REDIS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=roiraima-prod-redis-sg" \
  --region $REGION \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || echo "")

if [ "$REDIS_SG" = "None" ] || [ -z "$REDIS_SG" ]; then
  echo "  • Creando Security Group para Redis..."
  REDIS_SG=$(aws ec2 create-security-group \
    --group-name roiraima-prod-redis-sg \
    --description "Security group for roiraima production Redis cluster" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)
  
  # Agregar tags
  aws ec2 create-tags \
    --resources $REDIS_SG \
    --tags Key=Name,Value=roiraima-prod-redis-sg Key=Environment,Value=production \
    --region $REGION
  
  echo "  ✓ Redis SG creado: $REDIS_SG"
else
  echo "  ✓ Redis SG ya existe: $REDIS_SG"
fi

# Configurar reglas de entrada en RDS SG (permitir desde EC2)
echo "  • Configurando reglas RDS SG..."
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port $RDS_PORT \
  --source-group $EC2_SG \
  --region $REGION \
  2>/dev/null || echo "    (Regla ya existe o error)"

# Configurar reglas en Redis SG
echo "  • Configurando reglas Redis SG..."
aws ec2 authorize-security-group-ingress \
  --group-id $REDIS_SG \
  --protocol tcp \
  --port 6379 \
  --source-group $EC2_SG \
  --region $REGION \
  2>/dev/null || echo "    (Regla ya existe o error)"

# Permitir salida desde Redis a cualquier lugar
aws ec2 authorize-security-group-egress \
  --group-id $REDIS_SG \
  --protocol -1 \
  --cidr 0.0.0.0/0 \
  --region $REGION \
  2>/dev/null || echo "    (Regla ya existe o error)"

echo -e "${GREEN}✓ Security Groups configurados${NC}"
echo ""

#################################################################
# 2. CREAR ELASTICACHE REDIS
#################################################################

echo -e "${YELLOW}[2/5] Configurando ElastiCache Redis...${NC}"

# Verificar si Redis ya existe
REDIS_CLUSTER=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id roiraima-prod-redis \
  --region $REGION \
  --query 'CacheClusters[0].CacheClusterId' \
  --output text 2>/dev/null || echo "")

if [ "$REDIS_CLUSTER" = "roiraima-prod-redis" ]; then
  echo "  ✓ Redis cluster ya existe"
  REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id roiraima-prod-redis \
    --region $REGION \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
    --output text)
  REDIS_PORT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id roiraima-prod-redis \
    --region $REGION \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' \
    --output text)
else
  echo "  • Creando Redis cluster (t3.micro, 300 paquetes/mes)..."
  
  aws elasticache create-cache-cluster \
    --cache-cluster-id roiraima-prod-redis \
    --cache-node-type $REDIS_NODE_TYPE \
    --engine redis \
    --engine-version 7.0 \
    --num-cache-nodes 1 \
    --security-group-ids $REDIS_SG \
    --region $REGION \
    --tags Key=Name,Value=roiraima-prod-redis Key=Environment,Value=production \
    --preferred-availability-zone us-east-1a \
    --auto-minor-version-upgrade \
    --query 'CacheCluster.CacheClusterId' \
    --output text
  
  echo "  ⏳ Esperando que Redis esté disponible (esto toma ~5-10 minutos)..."
  
  # Esperar a que Redis esté disponible
  while true; do
    STATUS=$(aws elasticache describe-cache-clusters \
      --cache-cluster-id roiraima-prod-redis \
      --region $REGION \
      --query 'CacheClusters[0].CacheClusterStatus' \
      --output text)
    
    if [ "$STATUS" = "available" ]; then
      break
    fi
    echo "    Status: $STATUS... esperando..."
    sleep 10
  done
  
  REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id roiraima-prod-redis \
    --region $REGION \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
    --output text)
  
  REDIS_PORT=$(aws elasticache describe-cache-clusters \
    --cache-cluster-id roiraima-prod-redis \
    --region $REGION \
    --show-cache-node-info \
    --query 'CacheClusters[0].CacheNodes[0].Endpoint.Port' \
    --output text)
  
  echo -e "${GREEN}✓ Redis cluster creado y disponible${NC}"
fi

echo "  • Redis Endpoint: $REDIS_ENDPOINT:$REDIS_PORT"
echo ""

#################################################################
# 3. VALIDAR/CREAR S3 BUCKETS
#################################################################

echo -e "${YELLOW}[3/5] Validando S3 buckets...${NC}"

# Verificar bucket staging
if aws s3 ls "s3://$S3_BUCKET_STAGING" 2>/dev/null; then
  echo "  ✓ S3 Staging bucket existe: $S3_BUCKET_STAGING"
else
  echo "  • Creando S3 Staging bucket..."
  aws s3 mb "s3://$S3_BUCKET_STAGING" --region $REGION
  aws s3api put-bucket-tagging \
    --bucket $S3_BUCKET_STAGING \
    --tagging 'TagSet=[{Key=Environment,Value=staging},{Key=Project,Value=roiraima}]'
  echo "  ✓ S3 Staging bucket creado"
fi

# Verificar/crear bucket producción
if aws s3 ls "s3://$S3_BUCKET_PROD" 2>/dev/null; then
  echo "  ✓ S3 Production bucket existe: $S3_BUCKET_PROD"
else
  echo "  • Creando S3 Production bucket..."
  aws s3 mb "s3://$S3_BUCKET_PROD" --region $REGION
  aws s3api put-bucket-tagging \
    --bucket $S3_BUCKET_PROD \
    --tagging 'TagSet=[{Key=Environment,Value=production},{Key=Project,Value=roiraima}]'
  echo "  ✓ S3 Production bucket creado"
fi

echo ""

#################################################################
# 4. ASIGNAR ELASTIC IP
#################################################################

echo -e "${YELLOW}[4/5] Configurando Elastic IP...${NC}"

# Verificar si la instancia ya tiene Elastic IP
ELASTIC_IP=$(aws ec2 describe-instances \
  --instance-ids $EC2_INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].ElasticIpAddress' \
  --output text 2>/dev/null || echo "")

if [ "$ELASTIC_IP" = "None" ] || [ -z "$ELASTIC_IP" ]; then
  echo "  • Asignando Elastic IP a instancia..."
  ALLOC_ID=$(aws ec2 allocate-address \
    --domain vpc \
    --region $REGION \
    --query 'AllocationId' \
    --output text)
  
  aws ec2 associate-address \
    --instance-id $EC2_INSTANCE_ID \
    --allocation-id $ALLOC_ID \
    --region $REGION
  
  ELASTIC_IP=$(aws ec2 describe-addresses \
    --allocation-ids $ALLOC_ID \
    --region $REGION \
    --query 'Addresses[0].PublicIp' \
    --output text)
  
  echo "  ✓ Elastic IP asignada: $ELASTIC_IP"
else
  echo "  ✓ Elastic IP ya asignada: $ELASTIC_IP"
fi

echo ""

#################################################################
# 5. GENERAR ARCHIVO DE VARIABLES DE ENTORNO
#################################################################

echo -e "${YELLOW}[5/5] Generando archivo de variables de entorno...${NC}"

# Obtener datos de Secrets Manager
DB_USERNAME=$(aws secretsmanager get-secret-value \
  --secret-id roiraima/prod/rails-secrets \
  --region $REGION \
  --query 'SecretString' \
  --output text | jq -r '.db_username' 2>/dev/null || echo "postgres")

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id roiraima/prod/rails-secrets \
  --region $REGION \
  --query 'SecretString' \
  --output text | jq -r '.db_password' 2>/dev/null || echo "YOUR_DB_PASSWORD")

RAILS_MASTER_KEY=$(aws secretsmanager get-secret-value \
  --secret-id roiraima/prod/rails-secrets \
  --region $REGION \
  --query 'SecretString' \
  --output text | jq -r '.rails_master_key' 2>/dev/null || echo "YOUR_RAILS_MASTER_KEY")

# Crear archivo .env.production
cat > /tmp/.env.production << EOF
# ROIRAIMA PRODUCTION ENVIRONMENT
# Generado: $(date)

# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=$RAILS_MASTER_KEY

# Database
DATABASE_HOST=$RDS_ENDPOINT
DATABASE_PORT=$RDS_PORT
DATABASE_NAME=roiraima_prod
DATABASE_USERNAME=$DB_USERNAME
DATABASE_PASSWORD=$DB_PASSWORD

# Redis
REDIS_HOST=$REDIS_ENDPOINT
REDIS_PORT=$REDIS_PORT
REDIS_URL=redis://$REDIS_ENDPOINT:$REDIS_PORT/1

# AWS
AWS_REGION=$REGION
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_KEY
AWS_S3_BUCKET=$S3_BUCKET_PROD

# Application
DOMAIN=rutiservice.com
APP_HOST=18.208.221.245
PUBLIC_IP=$ELASTIC_IP

# Sidekiq
SIDEKIQ_CONCURRENCY=5
SIDEKIQ_TIMEOUT=25

# Logging
LOG_LEVEL=info
EOF

echo "  ✓ Archivo .env.production creado en /tmp/.env.production"
echo ""

#################################################################
# RESUMEN
#################################################################

echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✓ SETUP COMPLETADO${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""
echo -e "${YELLOW}RESUMEN DE RECURSOS:${NC}"
echo ""
echo "  Security Groups:"
echo "    • RDS SG: $RDS_SG_ID"
echo "    • EC2 SG: $EC2_SG"
echo "    • Redis SG: $REDIS_SG"
echo ""
echo "  Database:"
echo "    • Host: $RDS_ENDPOINT"
echo "    • Port: $RDS_PORT"
echo ""
echo "  Redis:"
echo "    • Endpoint: $REDIS_ENDPOINT:$REDIS_PORT"
echo "    • Cluster ID: roiraima-prod-redis"
echo ""
echo "  S3 Buckets:"
echo "    • Staging: $S3_BUCKET_STAGING"
echo "    • Production: $S3_BUCKET_PROD"
echo ""
echo "  Elastic IP:"
echo "    • IP: $ELASTIC_IP"
echo "    • Instance: $EC2_INSTANCE_ID"
echo ""
echo "  Archivo de configuración:"
echo "    • Ubicación: /tmp/.env.production"
echo ""
echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
echo "  1. Copiar /tmp/.env.production a tu proyecto"
echo "  2. Actualizar docker-compose.production.yml"
echo "  3. Desplegar la aplicación"
echo ""
echo -e "${BLUE}=====================================================${NC}"