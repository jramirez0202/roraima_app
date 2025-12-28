# Setup de Producción

**Última actualización:** Diciembre 2025

Esta guía cubre el deployment de Roraima Delivery a entornos de producción.

## Requisitos de Producción

### Infraestructura Mínima

- **Servidor de Aplicación:** 2 GB RAM, 2 vCPUs (mínimo)
- **Base de Datos:** PostgreSQL 12+ con extensión `pg_trgm`
- **Redis:** Para Sidekiq (background jobs)
- **Almacenamiento:** 20 GB para archivos (logos, PDFs, CSVs)
- **SSL/TLS:** Certificado válido (Let's Encrypt recomendado)

### Software Requerido

- Ruby 3.2.2
- Rails 7.1.5
- PostgreSQL 12+
- Redis 6+
- Nginx (reverse proxy)
- Passenger o Puma (app server)

## Opciones de Deployment

### Opción 1: Heroku (Recomendado para MVP)

#### Ventajas
- ✅ Setup rápido (< 30 minutos)
- ✅ SSL/TLS automático
- ✅ Backups automáticos de BD
- ✅ Escalado sencillo
- ✅ Add-ons integrados (Redis, PostgreSQL)

#### Pasos

1. **Crear cuenta en Heroku**
   ```bash
   heroku login
   ```

2. **Crear aplicación**
   ```bash
   heroku create roraima-delivery-production
   ```

3. **Agregar add-ons**
   ```bash
   # PostgreSQL (Hobby Dev es gratis)
   heroku addons:create heroku-postgresql:mini

   # Redis para Sidekiq
   heroku addons:create heroku-redis:mini

   # Papertrail para logs (opcional)
   heroku addons:create papertrail:choklad
   ```

4. **Configurar variables de entorno**
   ```bash
   heroku config:set RAILS_ENV=production
   heroku config:set RAILS_SERVE_STATIC_FILES=true
   heroku config:set RAILS_LOG_TO_STDOUT=true
   heroku config:set LANG=en_US.UTF-8
   heroku config:set RACK_ENV=production

   # Rails master key
   heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)

   # Sidekiq Web UI (opcional)
   heroku config:set SIDEKIQ_USERNAME=admin
   heroku config:set SIDEKIQ_PASSWORD=tu_password_seguro
   ```

5. **Desplegar**
   ```bash
   git push heroku main

   # Ejecutar migraciones
   heroku run rails db:migrate

   # Cargar seeds (regiones, comunas)
   heroku run rails db:seed

   # Habilitar extensión pg_trgm
   heroku pg:psql
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   \q
   ```

6. **Escalar dynos**
   ```bash
   # Web dyno (Rails)
   heroku ps:scale web=1

   # Worker dyno (Sidekiq)
   heroku ps:scale worker=1
   ```

7. **Configurar Procfile**

   El proyecto ya incluye un `Procfile`:

   ```
   web: bundle exec puma -C config/puma.rb
   worker: bundle exec sidekiq -C config/sidekiq.yml
   ```

8. **Ver logs**
   ```bash
   heroku logs --tail
   ```

#### Costos Estimados (Heroku)

- **Hobby Plan:** ~$25-50/mes
  - Eco Dynos: $5/mes cada uno (web + worker)
  - PostgreSQL Mini: $5/mes
  - Redis Mini: $3/mes

- **Production Plan:** ~$100-200/mes
  - Standard Dynos: $25/mes cada uno
  - PostgreSQL Standard: $50/mes
  - Redis Premium: $15/mes

---

### Opción 2: VPS (DigitalOcean, Linode, AWS EC2)

#### Ventajas
- ✅ Mayor control sobre infraestructura
- ✅ Costos potencialmente menores a largo plazo
- ✅ Personalización completa

#### Desventajas
- ⚠️ Requiere conocimientos de DevOps
- ⚠️ Mantenimiento manual
- ⚠️ Setup más complejo

#### Pasos (Ubuntu 22.04 LTS)

1. **Conectar al servidor**
   ```bash
   ssh root@tu-servidor-ip
   ```

2. **Crear usuario deploy**
   ```bash
   adduser deploy
   usermod -aG sudo deploy
   su - deploy
   ```

3. **Instalar dependencias**
   ```bash
   # Actualizar sistema
   sudo apt update && sudo apt upgrade -y

   # Instalar Ruby (rbenv)
   sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev \
     autoconf bison build-essential libyaml-dev libreadline-dev \
     libncurses5-dev libffi-dev libgdbm-dev

   curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

   echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
   echo 'eval "$(rbenv init -)"' >> ~/.bashrc
   source ~/.bashrc

   rbenv install 3.2.2
   rbenv global 3.2.2

   # Instalar Bundler
   gem install bundler

   # Instalar PostgreSQL
   sudo apt install -y postgresql postgresql-contrib libpq-dev
   sudo systemctl start postgresql
   sudo systemctl enable postgresql

   # Instalar Redis
   sudo apt install -y redis-server
   sudo systemctl start redis-server
   sudo systemctl enable redis-server

   # Instalar Nginx
   sudo apt install -y nginx
   sudo systemctl start nginx
   sudo systemctl enable nginx

   # Instalar Node.js (para importmaps)
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   ```

4. **Configurar PostgreSQL**
   ```bash
   sudo -u postgres psql

   CREATE DATABASE roraima_app_production;
   CREATE USER roraima WITH PASSWORD 'tu_password_seguro_aqui';
   ALTER DATABASE roraima_app_production OWNER TO roraima;
   GRANT ALL PRIVILEGES ON DATABASE roraima_app_production TO roraima;

   \c roraima_app_production
   CREATE EXTENSION pg_trgm;
   \q
   ```

5. **Clonar repositorio**
   ```bash
   cd /home/deploy
   git clone https://github.com/tu-usuario/roraima_delivery.git
   cd roraima_delivery/roraima_app
   ```

6. **Instalar gemas**
   ```bash
   bundle install --deployment --without development test
   ```

7. **Configurar variables de entorno**

   Crear `/home/deploy/roraima_delivery/roraima_app/.env`:

   ```bash
   RAILS_ENV=production
   DATABASE_PASSWORD=tu_password_seguro_aqui
   SECRET_KEY_BASE=$(rails secret)
   RAILS_SERVE_STATIC_FILES=true
   RAILS_LOG_TO_STDOUT=false

   SIDEKIQ_USERNAME=admin
   SIDEKIQ_PASSWORD=tu_password_sidekiq
   ```

8. **Ejecutar migraciones y assets**
   ```bash
   RAILS_ENV=production rails db:migrate
   RAILS_ENV=production rails db:seed
   RAILS_ENV=production rails assets:precompile
   ```

9. **Configurar Nginx**

   Crear `/etc/nginx/sites-available/roraima`:

   ```nginx
   upstream roraima_app {
     server unix:///home/deploy/roraima_delivery/roraima_app/tmp/sockets/puma.sock;
   }

   server {
     listen 80;
     server_name tu-dominio.com www.tu-dominio.com;

     root /home/deploy/roraima_delivery/roraima_app/public;

     location / {
       proxy_pass http://roraima_app;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
     }

     location ~ ^/(assets|packs)/ {
       gzip_static on;
       expires max;
       add_header Cache-Control public;
     }

     error_page 500 502 503 504 /500.html;
     client_max_body_size 50M;
   }
   ```

   Habilitar sitio:

   ```bash
   sudo ln -s /etc/nginx/sites-available/roraima /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```

10. **Configurar systemd para Puma**

    Crear `/etc/systemd/system/puma.service`:

    ```ini
    [Unit]
    Description=Puma HTTP Server
    After=network.target

    [Service]
    Type=simple
    User=deploy
    WorkingDirectory=/home/deploy/roraima_delivery/roraima_app
    ExecStart=/home/deploy/.rbenv/shims/bundle exec puma -C config/puma.rb
    Restart=always

    [Install]
    WantedBy=multi-user.target
    ```

    Iniciar servicio:

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl start puma
    sudo systemctl enable puma
    ```

11. **Configurar systemd para Sidekiq**

    Crear `/etc/systemd/system/sidekiq.service`:

    ```ini
    [Unit]
    Description=Sidekiq Background Worker
    After=network.target

    [Service]
    Type=simple
    User=deploy
    WorkingDirectory=/home/deploy/roraima_delivery/roraima_app
    ExecStart=/home/deploy/.rbenv/shims/bundle exec sidekiq -C config/sidekiq.yml
    Restart=always

    [Install]
    WantedBy=multi-user.target
    ```

    Iniciar servicio:

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl start sidekiq
    sudo systemctl enable sidekiq
    ```

12. **Configurar SSL con Let's Encrypt**

    ```bash
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com
    ```

---

### Opción 3: Docker Swarm / Kubernetes (Avanzado)

Para deployments de alta disponibilidad, consultar:
- [Setup con Docker](./docker.md)
- Documentación de Docker Swarm
- Documentación de Kubernetes

---

## Configuración de Base de Datos

### PostgreSQL en Producción

**IMPORTANTE:** Configurar puerto 5433 si es necesario:

```yaml
# config/database.yml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DATABASE_HOST") { "localhost" } %>
  port: <%= ENV.fetch("DATABASE_PORT") { 5433 } %>
  database: roraima_app_production
  username: roraima
  password: <%= ENV['DATABASE_PASSWORD'] %>
```

### Backups

#### Heroku

```bash
# Crear backup manual
heroku pg:backups:capture

# Descargar backup
heroku pg:backups:download

# Programar backups automáticos (requiere plan pagado)
heroku pg:backups:schedule --at '02:00 America/Santiago'
```

#### VPS

Crear script `/home/deploy/backup.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/deploy/backups"
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
pg_dump -h localhost -p 5433 -U roraima roraima_app_production | \
  gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Rotar backups (mantener últimos 7 días)
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +7 -delete

# Backup archivos (Active Storage)
tar -czf $BACKUP_DIR/files_backup_$DATE.tar.gz /home/deploy/roraima_delivery/roraima_app/storage
```

Cron job (`crontab -e`):

```bash
0 2 * * * /home/deploy/backup.sh
```

---

## Monitoreo y Logs

### Heroku

```bash
# Ver logs en tiempo real
heroku logs --tail

# Logs de Sidekiq
heroku logs --tail --dyno worker

# Papertrail (si está instalado)
heroku addons:open papertrail
```

### VPS

```bash
# Logs de Rails (production.log)
tail -f /home/deploy/roraima_delivery/roraima_app/log/production.log

# Logs de Puma
sudo journalctl -u puma -f

# Logs de Sidekiq
sudo journalctl -u sidekiq -f

# Logs de Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Herramientas de Monitoreo (Recomendadas)

- **New Relic:** APM y monitoreo de performance
- **Sentry:** Error tracking
- **Scout APM:** Performance monitoring
- **Datadog:** Monitoreo integral

---

## Checklist de Pre-Deployment

- [ ] `config/credentials.yml.enc` configurado
- [ ] Variables de entorno configuradas
- [ ] PostgreSQL con extensión `pg_trgm` habilitada
- [ ] Redis configurado para Sidekiq
- [ ] Migraciones ejecutadas (`rails db:migrate`)
- [ ] Seeds ejecutados (`rails db:seed`)
- [ ] Assets precompilados (`rails assets:precompile`)
- [ ] SSL/TLS configurado
- [ ] Backups automáticos configurados
- [ ] Monitoreo de errores configurado
- [ ] Crear usuario admin inicial
- [ ] Probar carga masiva de paquetes
- [ ] Probar generación de etiquetas PDF

---

## Troubleshooting en Producción

### Error: Secret key base is not set

```bash
# Generar secret
rails secret

# Configurar en Heroku
heroku config:set SECRET_KEY_BASE=tu_secret_generado

# O en .env (VPS)
echo "SECRET_KEY_BASE=tu_secret_generado" >> .env
```

### Error: Extension pg_trgm not found

```bash
# Heroku
heroku pg:psql
CREATE EXTENSION pg_trgm;

# VPS
sudo -u postgres psql roraima_app_production
CREATE EXTENSION pg_trgm;
```

### Sidekiq no procesa jobs

```bash
# Verificar Redis
redis-cli ping

# Heroku - Verificar worker dyno
heroku ps

# Heroku - Escalar worker
heroku ps:scale worker=1

# VPS - Reiniciar Sidekiq
sudo systemctl restart sidekiq
```

### Assets no cargan

```bash
# Recompilar assets
RAILS_ENV=production rails assets:precompile

# Heroku - Assets se compilan automáticamente
# Si no, forzar:
heroku run rails assets:precompile
```

---

## Mantenimiento

### Actualizar la Aplicación

#### Heroku

```bash
git pull origin main
git push heroku main
heroku run rails db:migrate
heroku restart
```

#### VPS

```bash
cd /home/deploy/roraima_delivery/roraima_app
git pull origin main
bundle install --deployment
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails assets:precompile
sudo systemctl restart puma
sudo systemctl restart sidekiq
```

### Limpiar Logs Antiguos

```bash
# Limpiar logs de Rails
RAILS_ENV=production rails log:clear

# Rotar logs manualmente
logrotate -f /etc/logrotate.d/rails
```

---

## Referencias

- [Setup Local](./local.md)
- [Setup con Docker](./docker.md)
- [Troubleshooting](../troubleshooting/errores-comunes.md)
- [Heroku Ruby Guide](https://devcenter.heroku.com/articles/getting-started-with-rails7)
