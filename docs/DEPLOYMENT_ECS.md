# 🚀 Guía de Deployment a AWS ECS Fargate

**Última actualización:** Diciembre 2025
**Ambiente:** Staging → Production
**Aplicación:** Roraima Delivery (Rails 7.1.5 + PostgreSQL + Redis + Sidekiq)

---

## 📚 Índice

1. [Arquitectura ECS](#arquitectura-ecs)
2. [Prerrequisitos](#prerrequisitos)
3. [Paso 1: Preparar Imagen Docker](#paso-1-preparar-imagen-docker)
4. [Paso 2: Configurar RDS PostgreSQL](#paso-2-configurar-rds-postgresql)
5. [Paso 3: Configurar ElastiCache Redis](#paso-3-configurar-elasticache-redis)
6. [Paso 4: Crear ECS Cluster](#paso-4-crear-ecs-cluster)
7. [Paso 5: Crear Task Definition](#paso-5-crear-task-definition)
8. [Paso 6: Crear ECS Service](#paso-6-crear-ecs-service)
9. [Paso 7: Configurar Load Balancer](#paso-7-configurar-load-balancer)
10. [Paso 8: Variables de Entorno](#paso-8-variables-de-entorno)
11. [Paso 9: Desplegar](#paso-9-desplegar)
12. [Troubleshooting](#troubleshooting)
13. [Costos Estimados](#costos-estimados)

---

## 🏗️ Arquitectura ECS

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-east-1)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Application Load Balancer (ALB)                         │  │
│  │  - HTTPS (443) con certificado SSL                       │  │
│  │  - HTTP (80) → redirect a HTTPS                          │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│                       │                                         │
│  ┌────────────────────▼─────────────────────────────────────┐  │
│  │  ECS Cluster: roraima-staging                            │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────┐     │  │
│  │  │ ECS Service: roraima-web (Fargate)              │     │  │
│  │  │ - Desired: 2 tasks                              │     │  │
│  │  │ - Min: 1, Max: 4 (auto-scaling)                │     │  │
│  │  │                                                 │     │  │
│  │  │  ┌──────────────┐    ┌──────────────┐          │     │  │
│  │  │  │  Web Task 1  │    │  Web Task 2  │          │     │  │
│  │  │  │  (Rails)     │    │  (Rails)     │          │     │  │
│  │  │  │  Port: 3000  │    │  Port: 3000  │          │     │  │
│  │  │  │  CPU: 0.5    │    │  CPU: 0.5    │          │     │  │
│  │  │  │  RAM: 1GB    │    │  RAM: 1GB    │          │     │  │
│  │  │  └──────────────┘    └──────────────┘          │     │  │
│  │  └─────────────────────────────────────────────────┘     │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────┐     │  │
│  │  │ ECS Service: roraima-sidekiq (Fargate)          │     │  │
│  │  │ - Desired: 1 task                               │     │  │
│  │  │                                                 │     │  │
│  │  │  ┌──────────────┐                               │     │  │
│  │  │  │ Sidekiq Task │                               │     │  │
│  │  │  │ (Workers)    │                               │     │  │
│  │  │  │ CPU: 0.25    │                               │     │  │
│  │  │  │ RAM: 512MB   │                               │     │  │
│  │  │  └──────────────┘                               │     │  │
│  │  └─────────────────────────────────────────────────┘     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                       │                  │                      │
│            ┌──────────▼──────┐  ┌───────▼──────────┐           │
│            │   RDS PostgreSQL │  │ ElastiCache Redis│           │
│            │   (db.t3.micro)  │  │ (cache.t3.micro) │           │
│            │   Port: 5432     │  │ Port: 6379       │           │
│            └──────────────────┘  └──────────────────┘           │
│                       │                  │                      │
│            ┌──────────▼──────────────────▼──────────┐           │
│            │         S3 Bucket                      │           │
│            │  checkpoint-active-storage-dev         │           │
│            │  (ActiveStorage files)                 │           │
│            └────────────────────────────────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Componentes:**
- **ALB:** Distribuye tráfico entre tasks, SSL termination
- **ECS Web Service:** 2 tasks de Rails (auto-scaling hasta 4)
- **ECS Sidekiq Service:** 1 task de Sidekiq para background jobs
- **RDS PostgreSQL:** Base de datos managed (port 5432)
- **ElastiCache Redis:** Cache + Sidekiq queues (port 6379)
- **S3:** Almacenamiento de archivos (logos, CSVs, PDFs)

---

## ✅ Prerrequisitos

### 1. Herramientas Instaladas
```bash
# AWS CLI
aws --version
# aws-cli/2.x.x

# Docker
docker --version
# Docker version 24.x.x

# (Opcional) ECS CLI
ecs-cli --version
```

### 2. AWS Configurado
```bash
# Configurar credenciales
aws configure
# AWS Access Key ID: AKIA...
# AWS Secret Access Key: ...
# Default region: us-east-1
# Default output format: json

# Verificar
aws sts get-caller-identity
```

### 3. Recursos AWS Ya Creados
- ✅ Bucket S3: `checkpoint-active-storage-dev`
- ✅ Rol IAM con política `CheckpointActiveStorageDevPolicy`

---

## 📦 Paso 1: Preparar Imagen Docker

### 1.1 Crear ECR Repository
```bash
# Crear repositorio para la imagen Docker
aws ecr create-repository \
  --repository-name roraima-delivery \
  --region us-east-1

# Output:
# {
#   "repository": {
#     "repositoryUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery"
#   }
# }

# Guardar este URI para usarlo después
```

### 1.2 Autenticarse con ECR
```bash
# Login en ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### 1.3 Build y Push de la Imagen
```bash
# Navegar al directorio del proyecto
cd /home/omen/Escritorio/Repos/Rails/Roraima_delivery/roraima_app

# Build para producción
docker build -t roraima-delivery:latest .

# Tag con el URI de ECR
docker tag roraima-delivery:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:latest

# Push a ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:latest
```

### 1.4 Versiones Tagged (Recomendado)
```bash
# Tag con versión específica
docker tag roraima-delivery:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:v1.0.0

docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:v1.0.0
```

---

## 🗄️ Paso 2: Configurar RDS PostgreSQL

### 2.1 Crear Subnet Group
```bash
# Primero obtener las subnets de tu VPC default
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-XXXXXXXX"

# Crear subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name roraima-subnet-group \
  --db-subnet-group-description "Subnet group for Roraima DB" \
  --subnet-ids subnet-AAAAAAAA subnet-BBBBBBBB subnet-CCCCCCCC
```

### 2.2 Crear Security Group para RDS
```bash
# Crear security group
aws ec2 create-security-group \
  --group-name roraima-rds-sg \
  --description "Security group for Roraima RDS" \
  --vpc-id vpc-XXXXXXXX

# Output: sg-XXXXXXXXX (guardar este ID)

# Permitir tráfico PostgreSQL desde ECS (agregar después de crear ECS SG)
aws ec2 authorize-security-group-ingress \
  --group-id sg-XXXXXXXXX \
  --protocol tcp \
  --port 5432 \
  --source-group sg-YYYYYYYY  # ECS security group
```

### 2.3 Crear Instancia RDS
```bash
aws rds create-db-instance \
  --db-instance-identifier roraima-staging-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username roraima_admin \
  --master-user-password 'TU_PASSWORD_SEGURO_AQUI' \
  --allocated-storage 20 \
  --storage-type gp3 \
  --db-subnet-group-name roraima-subnet-group \
  --vpc-security-group-ids sg-XXXXXXXXX \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --publicly-accessible false \
  --storage-encrypted \
  --enable-cloudwatch-logs-exports '["postgresql"]' \
  --tags Key=Environment,Value=staging Key=Application,Value=roraima

# Esto tarda ~10-15 minutos en crear
# Verificar status:
aws rds describe-db-instances \
  --db-instance-identifier roraima-staging-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### 2.4 Obtener Endpoint de RDS
```bash
aws rds describe-db-instances \
  --db-instance-identifier roraima-staging-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text

# Output: roraima-staging-db.cXXXXXXXXXX.us-east-1.rds.amazonaws.com
# Guardar este endpoint para DATABASE_HOST
```

### 2.5 Crear Base de Datos Rails
```bash
# Conectar con psql (desde una instancia EC2 en la misma VPC, o via bastion host)
psql -h roraima-staging-db.cXXXXXXXXXX.us-east-1.rds.amazonaws.com \
     -U roraima_admin \
     -d postgres

# En psql:
CREATE DATABASE roraima_app_staging;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
\q
```

---

## 🔴 Paso 3: Configurar ElastiCache Redis

### 3.1 Crear Subnet Group
```bash
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name roraima-redis-subnet \
  --cache-subnet-group-description "Subnet group for Roraima Redis" \
  --subnet-ids subnet-AAAAAAAA subnet-BBBBBBBB
```

### 3.2 Crear Security Group para Redis
```bash
# Crear security group
aws ec2 create-security-group \
  --group-name roraima-redis-sg \
  --description "Security group for Roraima Redis" \
  --vpc-id vpc-XXXXXXXX

# Output: sg-ZZZZZZZZZ

# Permitir tráfico Redis desde ECS
aws ec2 authorize-security-group-ingress \
  --group-id sg-ZZZZZZZZZ \
  --protocol tcp \
  --port 6379 \
  --source-group sg-YYYYYYYY  # ECS security group
```

### 3.3 Crear Redis Cluster
```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id roraima-staging-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --cache-subnet-group-name roraima-redis-subnet \
  --security-group-ids sg-ZZZZZZZZZ \
  --snapshot-retention-limit 5 \
  --preferred-maintenance-window "sun:05:00-sun:06:00" \
  --tags Key=Environment,Value=staging Key=Application,Value=roraima

# Verificar status (tarda ~5-10 minutos)
aws elasticache describe-cache-clusters \
  --cache-cluster-id roraima-staging-redis \
  --show-cache-node-info
```

### 3.4 Obtener Endpoint de Redis
```bash
aws elasticache describe-cache-clusters \
  --cache-cluster-id roraima-staging-redis \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text

# Output: roraima-staging-redis.XXXXXX.0001.use1.cache.amazonaws.com
# Guardar este endpoint para REDIS_URL
```

---

## 🐳 Paso 4: Crear ECS Cluster

### 4.1 Crear Cluster
```bash
aws ecs create-cluster \
  --cluster-name roraima-staging \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy \
    capacityProvider=FARGATE,weight=1,base=0 \
  --tags key=Environment,value=staging key=Application,value=roraima

# Verificar
aws ecs describe-clusters --clusters roraima-staging
```

### 4.2 Crear Security Group para ECS
```bash
# Crear security group para tasks ECS
aws ec2 create-security-group \
  --group-name roraima-ecs-tasks-sg \
  --description "Security group for Roraima ECS tasks" \
  --vpc-id vpc-XXXXXXXX

# Output: sg-YYYYYYYY (guardar este ID)

# Permitir tráfico desde ALB al puerto 3000 (Rails)
aws ec2 authorize-security-group-ingress \
  --group-id sg-YYYYYYYY \
  --protocol tcp \
  --port 3000 \
  --source-group sg-ALB_SG_ID  # Crear después

# Permitir tráfico outbound (para descargar gems, conectar a RDS/Redis)
aws ec2 authorize-security-group-egress \
  --group-id sg-YYYYYYYY \
  --protocol -1 \
  --cidr 0.0.0.0/0
```

---

## 📋 Paso 5: Crear Task Definition

### 5.1 Crear Execution Role (para ECS)
```bash
# Este rol permite a ECS hacer pull de imágenes ECR y escribir logs a CloudWatch
cat > ecs-task-execution-role-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://ecs-task-execution-role-trust-policy.json

# Adjuntar política managed de AWS
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### 5.2 Usar el Rol IAM Ya Creado (Task Role)
El rol que ya creaste con la política `CheckpointActiveStorageDevPolicy` se usará como **Task Role** (le da permisos a la app para acceder a S3).

### 5.3 Crear Task Definition JSON

Crear archivo `task-definition-web.json`:

```json
{
  "family": "roraima-web",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/TU_ROL_IAM_S3",
  "containerDefinitions": [
    {
      "name": "web",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "RAILS_ENV",
          "value": "staging"
        },
        {
          "name": "RAILS_LOG_TO_STDOUT",
          "value": "true"
        },
        {
          "name": "RAILS_SERVE_STATIC_FILES",
          "value": "true"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/database_url"
        },
        {
          "name": "REDIS_URL",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/redis_url"
        },
        {
          "name": "RAILS_MASTER_KEY",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/master_key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/roraima-staging",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "web"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/up || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

### 5.4 Registrar Task Definition
```bash
# Crear log group primero
aws logs create-log-group --log-group-name /ecs/roraima-staging

# Registrar task definition
aws ecs register-task-definition --cli-input-json file://task-definition-web.json
```

### 5.5 Task Definition para Sidekiq

Crear `task-definition-sidekiq.json` (similar pero sin puerto y con comando de Sidekiq):

```json
{
  "family": "roraima-sidekiq",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/TU_ROL_IAM_S3",
  "containerDefinitions": [
    {
      "name": "sidekiq",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:latest",
      "essential": true,
      "command": ["bundle", "exec", "sidekiq"],
      "environment": [
        {
          "name": "RAILS_ENV",
          "value": "staging"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/database_url"
        },
        {
          "name": "REDIS_URL",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/redis_url"
        },
        {
          "name": "RAILS_MASTER_KEY",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/master_key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/roraima-staging",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "sidekiq"
        }
      }
    }
  ]
}
```

```bash
aws ecs register-task-definition --cli-input-json file://task-definition-sidekiq.json
```

---

## 🔧 Paso 6: Crear ECS Service

### 6.1 Service para Web (con ALB)
```bash
aws ecs create-service \
  --cluster roraima-staging \
  --service-name roraima-web \
  --task-definition roraima-web:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-AAAAAAAA,subnet-BBBBBBBB],
    securityGroups=[sg-YYYYYYYY],
    assignPublicIp=ENABLED
  }" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/roraima-web-tg/XXXXXXXXXXXX,containerName=web,containerPort=3000" \
  --health-check-grace-period-seconds 120 \
  --deployment-configuration "minimumHealthyPercent=100,maximumPercent=200"
```

### 6.2 Service para Sidekiq (sin ALB)
```bash
aws ecs create-service \
  --cluster roraima-staging \
  --service-name roraima-sidekiq \
  --task-definition roraima-sidekiq:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-AAAAAAAA,subnet-BBBBBBBB],
    securityGroups=[sg-YYYYYYYY],
    assignPublicIp=ENABLED
  }"
```

---

## ⚖️ Paso 7: Configurar Load Balancer

### 7.1 Crear Application Load Balancer
```bash
# Crear ALB
aws elbv2 create-load-balancer \
  --name roraima-staging-alb \
  --subnets subnet-AAAAAAAA subnet-BBBBBBBB \
  --security-groups sg-ALB_SG \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --tags Key=Environment,Value=staging

# Output: LoadBalancerArn (guardar)
```

### 7.2 Crear Target Group
```bash
aws elbv2 create-target-group \
  --name roraima-web-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-XXXXXXXX \
  --target-type ip \
  --health-check-enabled \
  --health-check-protocol HTTP \
  --health-check-path /up \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3

# Output: TargetGroupArn (guardar)
```

### 7.3 Crear Listener HTTP (redirect a HTTPS)
```bash
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/roraima-staging-alb/XXXXXXXXXXXX \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}"
```

### 7.4 Crear Listener HTTPS (requiere certificado ACM)
```bash
# Primero solicitar certificado SSL en ACM para tu dominio
aws acm request-certificate \
  --domain-name staging.roraima.cl \
  --validation-method DNS

# Después de validar el certificado, crear listener HTTPS
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/roraima-staging-alb/XXXXXXXXXXXX \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/XXXXXXXXXXXX \
  --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/roraima-web-tg/XXXXXXXXXXXX
```

---

## 🔐 Paso 8: Variables de Entorno

### 8.1 Almacenar Secretos en AWS Systems Manager Parameter Store
```bash
# DATABASE_URL
aws ssm put-parameter \
  --name /roraima/staging/database_url \
  --type SecureString \
  --value "postgresql://roraima_admin:TU_PASSWORD@roraima-staging-db.cXXXXXXXXXX.us-east-1.rds.amazonaws.com:5432/roraima_app_staging"

# REDIS_URL
aws ssm put-parameter \
  --name /roraima/staging/redis_url \
  --type SecureString \
  --value "redis://roraima-staging-redis.XXXXXX.0001.use1.cache.amazonaws.com:6379/0"

# RAILS_MASTER_KEY (desde config/master.key en local)
aws ssm put-parameter \
  --name /roraima/staging/master_key \
  --type SecureString \
  --value "CONTENIDO_DE_MASTER_KEY_AQUI"
```

### 8.2 Dar Permisos al Execution Role para Leer Secretos
```bash
cat > ssm-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:ssm:us-east-1:123456789012:parameter/roraima/staging/*"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-name ReadSSMParameters \
  --policy-document file://ssm-policy.json
```

---

## 🚢 Paso 9: Desplegar

### 9.1 Ejecutar Migraciones (One-Time Task)
```bash
# Crear override JSON para task de migración
cat > run-migrations.json <<EOF
{
  "containerOverrides": [
    {
      "name": "web",
      "command": ["bundle", "exec", "rails", "db:migrate"]
    }
  ]
}
EOF

# Ejecutar task de migración
aws ecs run-task \
  --cluster roraima-staging \
  --task-definition roraima-web:1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-AAAAAAAA],
    securityGroups=[sg-YYYYYYYY],
    assignPublicIp=ENABLED
  }" \
  --overrides file://run-migrations.json

# Monitorear logs en CloudWatch:
# /ecs/roraima-staging/web/<task-id>
```

### 9.2 Verificar Deployment
```bash
# Ver status de services
aws ecs describe-services \
  --cluster roraima-staging \
  --services roraima-web roraima-sidekiq

# Ver tasks corriendo
aws ecs list-tasks --cluster roraima-staging

# Ver logs en tiempo real
aws logs tail /ecs/roraima-staging --follow
```

### 9.3 Obtener URL del ALB
```bash
aws elbv2 describe-load-balancers \
  --names roraima-staging-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Output: roraima-staging-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com
# Acceder: http://roraima-staging-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com
```

---

## 🐛 Troubleshooting

### Problema: Tasks no arrancan
```bash
# Ver eventos del service
aws ecs describe-services \
  --cluster roraima-staging \
  --services roraima-web \
  --query 'services[0].events[:5]'

# Ver logs del contenedor
aws logs tail /ecs/roraima-staging --follow
```

**Errores comunes:**
- `CannotPullContainerError` → Verificar execution role tiene permisos ECR
- `ResourceInitializationError` → Verificar subnet tiene internet (NAT gateway o public IP)
- `Unhealthy` → Verificar health check path `/up` responde 200

### Problema: No puedo acceder a RDS/Redis desde ECS
```bash
# Verificar security groups permiten tráfico
aws ec2 describe-security-groups --group-ids sg-XXXXXXXXX

# Verificar que tasks están en la misma VPC que RDS/Redis
aws ecs describe-tasks \
  --cluster roraima-staging \
  --tasks <task-arn> \
  --query 'tasks[0].attachments[0].details'
```

### Problema: ActiveStorage no sube archivos a S3
```bash
# Verificar que task role tiene permisos S3
aws iam get-role-policy \
  --role-name TU_ROL_IAM_S3 \
  --policy-name CheckpointActiveStorageDevPolicy

# Verificar en logs de Rails
aws logs filter-pattern /ecs/roraima-staging --filter-pattern "Aws::S3"
```

---

## 💰 Costos Estimados (Staging)

| Servicio | Especificación | Costo Mensual (USD) |
|----------|----------------|---------------------|
| **ECS Fargate** | 2 tasks web (0.5 vCPU, 1GB RAM) | ~$30 |
| **ECS Fargate** | 1 task sidekiq (0.25 vCPU, 512MB RAM) | ~$7 |
| **RDS PostgreSQL** | db.t3.micro (1 vCPU, 1GB RAM) | ~$15 |
| **ElastiCache Redis** | cache.t3.micro (2 vCPU, 0.5GB RAM) | ~$12 |
| **Application Load Balancer** | ALB + 2 target groups | ~$16 |
| **S3 + Data Transfer** | Según uso (estimado) | ~$5 |
| **CloudWatch Logs** | 5GB/mes (estimado) | ~$2.50 |
| **NAT Gateway** | Si no usas public IP en tasks | ~$32 |
| **TOTAL (sin NAT)** | | **~$87.50/mes** |
| **TOTAL (con NAT)** | | **~$120/mes** |

**Optimizaciones:**
- Usar `assignPublicIp=ENABLED` en tasks → Evita NAT Gateway (-$32/mes)
- Usar Fargate Spot → 70% descuento en tasks (no críticos)
- Apagar staging fuera de horario laboral → Ahorro 50%

---

## 🔄 Actualizar Deployment

### Opción 1: New Image (Build + Push)
```bash
# Build nueva versión
docker build -t roraima-delivery:v1.1.0 .

# Tag y push
docker tag roraima-delivery:v1.1.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:v1.1.0
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/roraima-delivery:v1.1.0

# Actualizar task definition (cambiar image tag)
# Luego forzar nuevo deployment
aws ecs update-service \
  --cluster roraima-staging \
  --service roraima-web \
  --task-definition roraima-web:2 \
  --force-new-deployment
```

### Opción 2: Force New Deployment (misma imagen)
```bash
# Útil para aplicar cambios de env vars en SSM
aws ecs update-service \
  --cluster roraima-staging \
  --service roraima-web \
  --force-new-deployment
```

---

## ✅ Checklist Final

- [ ] ECR repository creado
- [ ] Imagen Docker build y pushed
- [ ] RDS PostgreSQL creado y accesible
- [ ] ElastiCache Redis creado y accesible
- [ ] ECS Cluster creado
- [ ] Security groups configurados correctamente
- [ ] Task Definitions registradas (web + sidekiq)
- [ ] ECS Services creados y running
- [ ] ALB creado con target group
- [ ] Listeners HTTP/HTTPS configurados
- [ ] Secretos almacenados en SSM Parameter Store
- [ ] Migraciones ejecutadas
- [ ] Health checks pasando
- [ ] App accesible vía ALB DNS
- [ ] S3 uploads funcionando correctamente

---

## 📚 Referencias

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
- [Rails on Docker Best Practices](https://docs.docker.com/samples/rails/)
- [ActiveStorage with S3](https://edgeguides.rubyonrails.org/active_storage_overview.html#s3-service-amazon-s3-and-s3-compatible-apis)

---

**Última actualización:** Diciembre 2025
**Contacto:** Para soporte, consultar documentación del proyecto o logs de CloudWatch
