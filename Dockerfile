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

# Copiar gemas
COPY --from=builder /rails/vendor/bundle /rails/vendor/bundle

# Copiar TODO el código (esto falta)
COPY --from=builder /rails /rails

# Variables de entorno
ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

# Crear usuario
RUN useradd rails --create-home --shell /bin/bash

# Directorios y permisos
RUN mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R rails:rails /rails

# Dar permisos a binarios
RUN find /rails/vendor/bundle/bin -type f -exec chmod +x {} \; && \
    find /rails/bin -type f -exec chmod +x {} \;

# Usuario no-root
USER rails:rails

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Comando
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

# ============================================
# STAGE 4: STAGING
# ============================================
FROM base AS staging

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libvips \
    postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="staging" \
    BUNDLE_DEPLOYMENT="0" \
    BUNDLE_WITHOUT="" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true" \
    PATH="/rails/vendor/bundle/bin:${PATH}"

COPY --from=builder /rails /rails

RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    find /rails/bin -type f -exec chmod +x {} \;

USER rails:rails

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["sh", "-c", "cd /rails && bundle install && bundle exec sidekiq -c 5 -v"]

# ============================================
# STAGE 5: PRODUCTION
# ============================================
FROM base AS production

# 1. PRIMERO: Instalar dependencias de runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libvips \
    postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 2. Configurar variables de entorno
ENV RAILS_ENV="staging" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true"

# 3. COPIAR gemas desde builder
COPY --from=builder /rails/vendor/bundle /rails/vendor/bundle

# 4. COPIAR código desde builder
COPY --from=builder /rails /rails

# 5. Dar permisos a binarios (AHORA SÍ existen)
RUN find /rails/vendor/bundle/bin -type f -exec chmod +x {} \; && \
    find /rails/vendor/bundle -name "*.so" -o -name "*.so.*" -exec chmod +x {} \; 2>/dev/null || true

# 6. Precompilar assets UNA SOLA VEZ
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# 7. Crear usuario y ajustar permisos finales
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    find /rails -type d -exec chmod 755 {} \; && \
    find /rails -type f -exec chmod 644 {} \; && \
    chmod -R 755 /rails/bin

# 8. Usuario no-root
USER rails:rails

# 9. Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

# 10. Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# 11. Puerto
EXPOSE 3000

# 12. Comando
CMD ["sh", "-c", "./bin/rails server -b 0.0.0.0 -p ${PORT:-3000}"]
