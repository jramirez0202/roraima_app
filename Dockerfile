# syntax = docker/dockerfile:1
# ============================================
# RORAIMA DELIVERY APP - Dockerfile
# ============================================
FROM registry.docker.com/library/ruby:3.2.2-slim AS base

WORKDIR /rails

ENV BUNDLE_PATH="/rails/vendor/bundle" \
    BUNDLE_BIN="/rails/vendor/bundle/bin" \
    GEM_HOME="/rails/vendor/bundle" \
    PATH="/rails/vendor/bundle/bin:${PATH}" \
    BUNDLE_WITHOUT=""

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    postgresql-client \
    libpq-dev \
    libvips \
    build-essential \
    git \
    pkg-config \
    curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# ============================================
# STAGE 2: BUILDER
# ============================================
FROM base AS builder

COPY Gemfile Gemfile.lock ./

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# ============================================
# STAGE 3: DEVELOPMENT
# ============================================
FROM base AS development

COPY --from=builder /rails/vendor/bundle /rails/vendor/bundle
COPY --from=builder /rails /rails

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

RUN useradd rails --create-home --shell /bin/bash
RUN mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R rails:rails /rails
RUN find /rails/vendor/bundle/bin -type f -exec chmod +x {} \; && \
    find /rails/bin -type f -exec chmod +x {} \;

USER rails:rails

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# ============================================
# STAGE 4: PRODUCTION
# ============================================
FROM base AS production

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

# 3. COPIAR gemas desde builder
COPY --from=builder /rails/vendor/bundle /rails/vendor/bundle

# 4. COPIAR código desde builder
COPY --from=builder /rails /rails

# Reinstalar gemas DESPUÉS de copiar el Gemfile
RUN bundle install --local || bundle install

# Verificar sidekiq
RUN which sidekiq && echo "Sidekiq found!" || (echo "Sidekiq not found!" && exit 1)

# 5. Dar permisos a binarios
RUN find /rails/vendor/bundle/bin -type f -exec chmod +x {} \; && \
    find /rails/vendor/bundle -name "*.so" -o -name "*.so.*" -exec chmod +x {} \; 2>/dev/null || true

# 6. Precompilar assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# 7. Crear usuario y ajustar permisos
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /rails && \
    find /rails -type d -exec chmod 755 {} \; && \
    find /rails -type f -exec chmod 644 {} \; && \
    chmod -R 755 /rails/bin

USER rails:rails

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["sh", "-c", "./bin/rails server -b 0.0.0.0 -p ${PORT:-3000}"]