# 🆓 Deployment a AWS EC2 con Free Tier

**Costo:** $0/mes durante 12 meses (Free Tier)
**Ambiente:** Staging
**Aplicación:** Roraima Delivery (Rails + PostgreSQL + Redis + Sidekiq)

---

## 📋 Requisitos Free Tier

✅ **EC2:** 750 horas/mes de t2.micro o t3.micro (1 instancia 24/7 gratis)
✅ **S3:** 5GB storage + 20,000 GET + 2,000 PUT
✅ **EBS:** 30GB de almacenamiento SSD
✅ **Data Transfer:** 100GB salida/mes

⚠️ **Importante:** Free Tier es válido por **12 meses** desde que creaste la cuenta AWS.

---

## 🎯 Arquitectura

```
Internet
   ↓
EC2 t3.micro (Public IP)
   ├── Docker Compose
   │   ├── Web (Rails:3000)
   │   ├── Sidekiq (Workers)
   │   ├── PostgreSQL (:5432)
   │   └── Redis (:6379)
   └── Volúmenes Docker
       ├── postgres_data
       └── redis_data
   ↓
S3: checkpoint-active-storage-dev
```

---

## 🚀 Paso 1: Crear Instancia EC2

### 1.1 Via AWS Console

1. Ir a **EC2 Dashboard** → **Launch Instance**

2. **Configuración:**
   - **Name:** `roraima-staging`
   - **AMI:** Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance type:** `t3.micro` ✅ (1 vCPU, 1GB RAM - Free Tier)
   - **Key pair:** Crear nuevo o usar existente (descarga `.pem`)
   - **Network settings:**
     - ✅ Allow SSH (port 22) from "My IP"
     - ✅ Allow HTTP (port 80) from "Anywhere"
     - ✅ Allow HTTPS (port 443) from "Anywhere"
   - **Storage:** 30GB gp3 (Free Tier incluye hasta 30GB)
   - **Advanced details:**
     - IAM instance profile: Seleccionar tu rol IAM con permisos S3

3. **Launch instance**

### 1.2 Via AWS CLI

```bash
# Obtener ID de la subnet default
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=default-for-az,Values=true" \
  --query 'Subnets[0].SubnetId' \
  --output text)

# Crear security group
aws ec2 create-security-group \
  --group-name roraima-staging-sg \
  --description "Security group for Roraima staging server"

SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=roraima-staging-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Reglas de seguridad
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp --port 22 --cidr $(curl -s ifconfig.me)/32  # SSH solo desde tu IP

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp --port 80 --cidr 0.0.0.0/0  # HTTP

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp --port 443 --cidr 0.0.0.0/0  # HTTPS

# Crear key pair (si no tienes)
aws ec2 create-key-pair \
  --key-name roraima-key \
  --query 'KeyMaterial' \
  --output text > roraima-key.pem

chmod 400 roraima-key.pem

# Lanzar instancia
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.micro \
  --key-name roraima-key \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --iam-instance-profile Name=TU_ROL_IAM_AQUI \
  --block-device-mappings 'DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=roraima-staging},{Key=Environment,Value=staging}]'
```

### 1.3 Obtener IP Pública

```bash
# Via CLI
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=roraima-staging" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# O en la consola AWS → EC2 → Instances
```

---

## 🔧 Paso 2: Configurar Servidor

### 2.1 Conectar via SSH

```bash
# Asegurar permisos de la key
chmod 400 roraima-key.pem

# Conectar
ssh -i roraima-key.pem ubuntu@XX.XX.XX.XX
```

### 2.2 Instalar Docker y Docker Compose

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario ubuntu al grupo docker
sudo usermod -aG docker ubuntu

# Cerrar sesión y volver a conectar para aplicar cambios
exit
ssh -i roraima-key.pem ubuntu@XX.XX.XX.XX

# Verificar Docker
docker --version
docker compose version
```

### 2.3 Instalar Utilidades

```bash
# Git
sudo apt install -y git

# Herramientas de build (para gems nativas)
sudo apt install -y build-essential libpq-dev
```

---

## 📦 Paso 3: Clonar Repositorio

```bash
# Clonar repo (usando HTTPS o SSH)
git clone https://github.com/TU_USUARIO/roraima_delivery.git

# O si es privado, configurar SSH key en GitHub primero
cd roraima_delivery/roraima_app
```

---

## 🔐 Paso 4: Configurar Variables de Entorno

### 4.1 Crear archivo .env

```bash
# En el servidor EC2
cd ~/roraima_delivery/roraima_app

cat > .env.staging <<EOF
# Rails
RAILS_ENV=staging
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# Database (PostgreSQL en Docker)
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_NAME=roraima_app_staging
DATABASE_USERNAME=roraima
DATABASE_PASSWORD=$(openssl rand -base64 32)

# Redis (en Docker)
REDIS_URL=redis://redis:6379/0

# Rails Master Key (desde tu config/master.key local)
RAILS_MASTER_KEY=PEGA_AQUI_CONTENIDO_DE_MASTER_KEY

# Puerto para acceso externo
PORT=80
EOF

# Verificar
cat .env.staging
```

### 4.2 Copiar Master Key desde Local

```bash
# En tu máquina LOCAL:
cat /home/omen/Escritorio/Repos/Rails/Roraima_delivery/roraima_app/config/master.key

# Copiar el contenido y pegarlo en .env.staging en el servidor
```

---

## 🐳 Paso 5: Crear docker-compose.production.yml

Crear archivo para producción/staging con configuración optimizada:

```bash
cat > docker-compose.production.yml <<'EOF'
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: roraima-db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${DATABASE_NAME}
      POSTGRES_USER: ${DATABASE_USERNAME}
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DATABASE_USERNAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: roraima-redis
    volumes:
      - redis_data:/data
    restart: unless-stopped
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  web:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: roraima-web
    command: bash -c "
      bundle exec rails db:prepare &&
      bundle exec rails assets:precompile &&
      bundle exec puma -C config/puma.rb"
    volumes:
      - ./log:/rails/log
      - ./tmp:/rails/tmp
    ports:
      - "${PORT:-80}:3000"
    env_file:
      - .env.staging
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3000/up || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  sidekiq:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: roraima-sidekiq
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - ./log:/rails/log
      - ./tmp:/rails/tmp
    env_file:
      - .env.staging
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
EOF
```

---

## 🚢 Paso 6: Desplegar

### 6.1 Build y Start

```bash
# Build de imágenes (primera vez)
docker compose -f docker-compose.production.yml build

# Iniciar servicios
docker compose -f docker-compose.production.yml up -d

# Ver logs
docker compose -f docker-compose.production.yml logs -f

# Verificar que todo está running
docker compose -f docker-compose.production.yml ps
```

### 6.2 Crear Base de Datos y Migrar

```bash
# Ejecutar migraciones
docker compose -f docker-compose.production.yml exec web \
  rails db:create db:migrate

# Instalar extensión pg_trgm
docker compose -f docker-compose.production.yml exec db \
  psql -U roraima -d roraima_app_staging -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

# Seed data (opcional)
docker compose -f docker-compose.production.yml exec web \
  rails db:seed
```

### 6.3 Verificar S3

```bash
# Probar conexión a S3 desde el contenedor
docker compose -f docker-compose.production.yml exec web rails console

# En la consola Rails:
ActiveStorage::Blob.service.bucket
# => "checkpoint-active-storage-dev"

ActiveStorage::Blob.service.client.config.credentials
# => Debe mostrar credenciales del rol IAM

exit
```

---

## 🌐 Paso 7: Configurar Dominio (Opcional)

### Opción A: Usar IP Pública directamente

```
http://XX.XX.XX.XX
```

### Opción B: Configurar dominio con Route 53

```bash
# Si tienes dominio staging.roraima.cl, crear record A:
# Type: A
# Name: staging
# Value: XX.XX.XX.XX (IP de la EC2)
# TTL: 300
```

### Opción C: Elastic IP (gratis si está asociada)

```bash
# Asignar Elastic IP (gratis mientras esté asociada a instancia)
aws ec2 allocate-address --domain vpc

# Asociar a instancia
aws ec2 associate-address \
  --instance-id i-XXXXXXXXX \
  --allocation-id eipalloc-XXXXXXXXX
```

---

## 🔒 Paso 8: Configurar HTTPS con Let's Encrypt (Opcional)

```bash
# Instalar Nginx
sudo apt install -y nginx certbot python3-certbot-nginx

# Configurar Nginx como reverse proxy
sudo nano /etc/nginx/sites-available/roraima

# Agregar:
server {
    listen 80;
    server_name staging.roraima.cl;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Activar sitio
sudo ln -s /etc/nginx/sites-available/roraima /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Obtener certificado SSL
sudo certbot --nginx -d staging.roraima.cl
```

---

## 🔄 Actualizar Deployment

```bash
# SSH al servidor
ssh -i roraima-key.pem ubuntu@XX.XX.XX.XX

# Ir al directorio
cd ~/roraima_delivery/roraima_app

# Pull últimos cambios
git pull origin main

# Rebuild y restart
docker compose -f docker-compose.production.yml build
docker compose -f docker-compose.production.yml up -d

# Ejecutar migraciones si hay
docker compose -f docker-compose.production.yml exec web rails db:migrate

# Ver logs
docker compose -f docker-compose.production.yml logs -f web
```

---

## 📊 Monitoreo

### Ver Logs en Tiempo Real

```bash
# Todos los servicios
docker compose -f docker-compose.production.yml logs -f

# Solo web
docker compose -f docker-compose.production.yml logs -f web

# Solo sidekiq
docker compose -f docker-compose.production.yml logs -f sidekiq
```

### Verificar Salud

```bash
# Status de contenedores
docker compose -f docker-compose.production.yml ps

# Uso de recursos
docker stats

# Health checks
curl http://localhost:3000/up
```

### CloudWatch (Opcional)

Instalar agente de CloudWatch para monitorear CPU/RAM (gratis en Free Tier):

```bash
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb
```

---

## 💰 Costos con Free Tier

| Recurso | Free Tier | Uso Estimado | Costo |
|---------|-----------|--------------|-------|
| **EC2 t3.micro** | 750 hrs/mes | 744 hrs/mes (24/7) | **$0** ✅ |
| **EBS 30GB** | 30GB | 30GB | **$0** ✅ |
| **S3 storage** | 5GB | 0.005GB (5MB) | **$0** ✅ |
| **S3 requests** | 20K GET, 2K PUT | ~100/mes | **$0** ✅ |
| **Data transfer** | 100GB out | ~5GB/mes | **$0** ✅ |
| **Elastic IP** | Gratis si asociada | 1 IP | **$0** ✅ |
| **TOTAL** | | | **$0/mes** 🎉 |

⚠️ **IMPORTANTE:** Esto es gratis por **12 meses** desde que creaste la cuenta AWS.

**Después de 12 meses:**
- EC2 t3.micro: ~$7.50/mes
- EBS 30GB: ~$3/mes
- S3: ~$0.12/mes
- **Total: ~$10.60/mes**

---

## 🔐 Seguridad

### Configurar Firewall

```bash
# UFW (Uncomplicated Firewall)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Verificar
sudo ufw status
```

### Actualizar Sistema Regularmente

```bash
# Cada semana
sudo apt update && sudo apt upgrade -y

# Reiniciar si es necesario
sudo reboot
```

### Backups

```bash
# Backup de PostgreSQL
docker compose -f docker-compose.production.yml exec db \
  pg_dump -U roraima roraima_app_staging > backup_$(date +%Y%m%d).sql

# Copiar a S3 (si configuraste AWS CLI en la instancia)
aws s3 cp backup_$(date +%Y%m%d).sql s3://checkpoint-active-storage-dev/backups/
```

---

## 🐛 Troubleshooting

### Contenedor no inicia

```bash
# Ver logs detallados
docker compose -f docker-compose.production.yml logs web

# Verificar variables de entorno
docker compose -f docker-compose.production.yml exec web env | grep RAILS
```

### No puedo conectar a S3

```bash
# Verificar rol IAM está asignado a la instancia
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Debe mostrar el nombre del rol
# Si no, reasignar rol IAM en EC2 console
```

### Puerto 80 no accesible

```bash
# Verificar que web está escuchando en 3000
docker compose -f docker-compose.production.yml exec web netstat -tuln | grep 3000

# Verificar security group permite puerto 80
aws ec2 describe-security-groups --group-ids $SG_ID
```

---

## ✅ Checklist Final

- [ ] Instancia EC2 t3.micro creada (Free Tier)
- [ ] Security group configurado (SSH, HTTP, HTTPS)
- [ ] Rol IAM con permisos S3 asignado a instancia
- [ ] Docker y Docker Compose instalados
- [ ] Repositorio clonado
- [ ] Variables de entorno configuradas (.env.staging)
- [ ] Docker Compose production configurado
- [ ] Contenedores running (web, sidekiq, db, redis)
- [ ] Migraciones ejecutadas
- [ ] Extensión pg_trgm instalada
- [ ] S3 funcionando (ActiveStorage)
- [ ] App accesible via IP pública
- [ ] (Opcional) Dominio configurado
- [ ] (Opcional) HTTPS con Let's Encrypt

---

## 📚 Referencias

- [AWS EC2 Free Tier](https://aws.amazon.com/free/)
- [Docker Compose Production](https://docs.docker.com/compose/production/)
- [Rails Production Guide](https://guides.rubyonrails.org/configuring.html#running-in-production-mode)

---

**Última actualización:** Diciembre 2025
