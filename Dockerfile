# syntax = docker/dockerfile:1

# ============================================
# RORAIMA DELIVERY APP - Dockerfile
# ============================================
# Este Dockerfile usa "multi-stage build" para crear imágenes optimizadas
# tanto para desarrollo como para producción.
#
# STAGES (etapas):
# 1. base       → Dependencias del sistema comunes
# 2. builder    → Compilación de gemas y assets
# 3. development → Imagen para desarrollo local
# 4. production → Imagen optimizada para producción
#
# USO:
# - Desarrollo:  docker compose build (usa target: development)
# - Producción:  docker build --target production -t roraima_app .
# ============================================

# ------------------------------------------
# ARGUMENTOS GLOBALES
# ------------------------------------------
# ARG define variables que se pueden usar en el build
# Asegúrate que coincida con .ruby-version y Gemfile
ARG RUBY_VERSION=3.2.2

# ============================================
# STAGE 1: BASE - Dependencias del Sistema
# ============================================
# Este stage instala las dependencias a nivel de sistema operativo
# que necesita Rails para funcionar. Se reutiliza en development y production.

FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Directorio de trabajo: toda la aplicación vivirá en /rails
WORKDIR /rails

# Variables de entorno comunes a todos los stages
# BUNDLE_PATH: Dónde Bundler instala las gemas
# BUNDLE_WITHOUT: Por ahora vacío (se sobrescribe en cada stage)
ENV BUNDLE_PATH="/rails/vendor/bundle" \
    BUNDLE_BIN="/rails/vendor/bundle/bin" \
    GEM_HOME="/rails/vendor/bundle" \
    PATH="/rails/vendor/bundle/bin:${PATH}" \
    BUNDLE_WITHOUT=""

# Instalar dependencias del sistema
# ¿Por qué un solo RUN? Cada RUN crea una "capa" en la imagen.
# Combinarlos ahorra espacio (~30-40% más pequeña)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    # PostgreSQL: cliente y librerías de desarrollo para compilar la gema 'pg'
    postgresql-client \
    libpq-dev \
    # ImageMagick/libvips: Procesamiento de imágenes (Active Storage)
    libvips \
    # Compilación de gemas nativas (nokogiri, pg, etc.)
    build-essential \
    git \
    pkg-config \
    # Utilidades
    curl && \
    # CRÍTICO: Limpiar cache de apt para reducir tamaño de imagen
    # Sin esto, la imagen pesa 100+ MB más
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# ============================================
# STAGE 2: BUILDER - Compilación de Gemas
# ============================================
# Este stage compila e instala todas las gemas.
# Es temporal: solo copiamos los archivos resultantes a los stages finales.

FROM base AS builder

# Copiar SOLO Gemfile y Gemfile.lock primero
# ¿Por qué no copiar todo el código aquí?
# Docker cachea cada instrucción. Si solo cambias código (no gemas),
# esta capa se reutiliza y NO ejecuta bundle install de nuevo.
# Esto ahorra 5-10 minutos en cada build!
COPY Gemfile Gemfile.lock ./

# Instalar gemas
RUN bundle install && \
    # Limpiar archivos innecesarios para reducir tamaño
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # Precompilar Bootsnap (acelera arranque de Rails)
    bundle exec bootsnap precompile --gemfile

# Ahora sí, copiar TODO el código de la aplicación
COPY . .

# Precompilar Bootsnap para archivos de la app (app/ y lib/)
# Bootsnap cachea la carga de archivos Ruby para arranques más rápidos
RUN bundle exec bootsnap precompile app/ lib/

# ============================================
# STAGE 3: DEVELOPMENT - Para Desarrollo Local
# ============================================
# Este stage se usa con docker-compose para desarrollo.
# Características:
# - Hot-reload (código se monta como volumen)
# - No precompila assets (Tailwind watch lo hace en vivo)
# - Healthcheck para verificar que Rails responde
# - Logs detallados

FROM base AS development

# Copiar gemas instaladas desde el stage builder
# --from=builder permite copiar archivos de OTRO stage
COPY --from=builder /rails/vendor/bundle /rails/vendor/bundle


# Variables de entorno para desarrollo
ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

# Crear usuario no-root para seguridad
# Aunque estemos en desarrollo, es buena práctica NO ejecutar como root
RUN useradd rails --create-home --shell /bin/bash

# Crear directorios necesarios y dar permisos al usuario rails
RUN mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R rails:rails /rails

# A partir de aquí, todos los comandos se ejecutan como usuario 'rails'
USER rails:rails

# HEALTHCHECK: Docker ejecuta este comando cada 30s para verificar que la app funciona
# Si falla 3 veces seguidas, marca el contenedor como "unhealthy"
# El endpoint /up es nuevo en Rails 7+ y responde 200 OK si la app está viva
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

# ENTRYPOINT se ejecuta ANTES del CMD
# Este script prepara la base de datos (migraciones, etc.)
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Comando por defecto: iniciar servidor Rails
# -b 0.0.0.0 hace que escuche en TODAS las interfaces (necesario para Docker)
# Sin esto, solo escucharía en localhost y no sería accesible desde el host
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# ============================================
# STAGE 4: PRODUCTION - Imagen Final Optimizada
# ============================================
# Este stage crea la imagen para producción.
# Características:
# - Assets precompilados
# - Solo dependencias de producción
# - Imagen más pequeña (~500 MB vs ~1.5 GB)
# - Usuario no-root (seguridad)

FROM base AS production

# Instalar SOLO las dependencias de runtime (no las de compilación)
# curl: Para healthchecks
# libvips: Procesamiento de imágenes en runtime
# postgresql-client: Para ejecutar comandos de DB
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libvips \
    postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Variables de entorno para producción
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true"

# Copiar gemas instaladas desde builder
COPY --from=builder /rails/vendor/bundle /rails/vendor/bundle

# Copiar código de la aplicación desde builder
COPY --from=builder /rails /rails

# Precompilar assets para producción
# SECRET_KEY_BASE_DUMMY permite precompilar sin tener el secret real
# (el secret real se pasa como variable de entorno en runtime)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Crear usuario rails y ajustar permisos
# IMPORTANTE: El usuario rails necesita permisos de lectura en toda la aplicación
# pero de escritura solo en db, log, storage, tmp
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    find /rails -type d -exec chmod 755 {} \; && \
    find /rails -type f -exec chmod 644 {} \; && \
    chmod -R 755 /rails/bin

# Cambiar a usuario no-root
USER rails:rails

# Healthcheck para producción
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/up || exit 1

# Entrypoint prepara la base de datos
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Exponer puerto 3000 (informativo, no abre el puerto automáticamente)
EXPOSE 3000

# Comando por defecto: servidor Rails
CMD ["./bin/rails", "server"]
