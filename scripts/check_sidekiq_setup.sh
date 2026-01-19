#!/bin/bash

echo "🔍 Verificando configuración de Sidekiq y Redis..."
echo ""

# Check if Redis is installed
if command -v redis-server &> /dev/null; then
    echo "✅ Redis está instalado"
else
    echo "❌ Redis NO está instalado"
    echo "   Instala con: sudo apt install redis-server (Linux)"
    echo "   o: brew install redis (macOS)"
    exit 1
fi

# Check if Redis is running
if redis-cli ping &> /dev/null; then
    echo "✅ Redis está corriendo"
else
    echo "❌ Redis NO está corriendo"
    echo "   Inicia con: sudo systemctl start redis-server"
    echo "   o: redis-server"
    exit 1
fi

# Check Redis connection
REDIS_VERSION=$(redis-cli --version | cut -d' ' -f2)
echo "✅ Redis version: $REDIS_VERSION"

# Check if Sidekiq gem is installed
if bundle show sidekiq &> /dev/null; then
    SIDEKIQ_VERSION=$(bundle show sidekiq | grep "sidekiq" | cut -d'-' -f2 | tr -d '()')
    echo "✅ Sidekiq gem instalada (versión: $SIDEKIQ_VERSION)"
else
    echo "❌ Sidekiq gem NO está instalada"
    echo "   Ejecuta: bundle install"
    exit 1
fi

# Check if roo gem is installed
if bundle show roo &> /dev/null; then
    echo "✅ Roo gem instalada (para parsear Excel)"
else
    echo "❌ Roo gem NO está instalada"
    exit 1
fi

# Check if Sidekiq is running
if pgrep -f sidekiq > /dev/null; then
    echo "✅ Sidekiq está corriendo"
    SIDEKIQ_PID=$(pgrep -f sidekiq)
    echo "   PID: $SIDEKIQ_PID"
else
    echo "⚠️  Sidekiq NO está corriendo"
    echo "   Inicia con: bundle exec sidekiq"
fi

# Check Rails server
if pgrep -f "rails server\|bin/rails s" > /dev/null; then
    echo "✅ Rails server está corriendo"
else
    echo "⚠️  Rails server NO está corriendo"
    echo "   Inicia con: bin/rails server"
fi

echo ""
echo "📊 Resumen:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if redis-cli ping &> /dev/null && pgrep -f sidekiq > /dev/null; then
    echo "🎉 ¡Todo listo! Puedes usar la carga masiva."
    echo ""
    echo "Accede a:"
    echo "  Admin:    http://localhost:3000/admin/bulk_uploads/new"
    echo "  Customer: http://localhost:3000/customers/bulk_uploads/new"
    echo "  Sidekiq:  http://localhost:3000/sidekiq (solo admins)"
else
    echo "⚠️  Faltan servicios por iniciar."
    echo ""
    echo "Pasos siguientes:"
    if ! redis-cli ping &> /dev/null; then
        echo "  1. Inicia Redis: sudo systemctl start redis-server"
    fi
    if ! pgrep -f sidekiq > /dev/null; then
        echo "  2. Inicia Sidekiq: bundle exec sidekiq"
    fi
    if ! pgrep -f "rails server\|bin/rails s" > /dev/null; then
        echo "  3. Inicia Rails: bin/rails server"
    fi
fi

echo ""
