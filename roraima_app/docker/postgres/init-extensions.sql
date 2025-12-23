-- ============================================
-- POSTGRESQL EXTENSIONS - Roraima Delivery App
-- ============================================
-- Este script se ejecuta AUTOMÁTICAMENTE la primera vez
-- que el contenedor de PostgreSQL se inicia.
--
-- ¿CÓMO FUNCIONA?
-- PostgreSQL ejecuta todos los archivos .sql que encuentra en
-- /docker-entrypoint-initdb.d/ durante la primera inicialización.
--
-- ¿CUÁNDO SE EJECUTA?
-- SOLO la primera vez (cuando el volumen postgres_data está vacío).
-- Si ya inicializaste Postgres antes y quieres re-ejecutar este script:
-- 1. Detener servicios: docker compose down
-- 2. Borrar volúmenes: docker compose down -v
-- 3. Volver a iniciar: docker compose up -d
--
-- UBICACIÓN:
-- Este archivo está en: docker/postgres/init-extensions.sql
-- Se monta en: /docker-entrypoint-initdb.d/01-extensions.sql
-- (El "01-" asegura que se ejecute primero si hay múltiples scripts)
-- ============================================

-- ------------------------------------------
-- EXTENSIÓN pg_trgm (Trigram)
-- ------------------------------------------
-- ¿QUÉ ES pg_trgm?
-- Habilita búsquedas eficientes tipo ILIKE usando índices GIN.
-- Rails usa esto para buscar tracking codes parciales.
--
-- EJEMPLO DE USO:
-- Buscar:   "PKG-861"
-- Encuentra: "PKG-86169301226465" (coincidencia parcial)
--
-- SIN pg_trgm: Scan completo de tabla (lento con millones de registros)
-- CON pg_trgm: Búsqueda por índice O(log n) (muy rápido)
--
-- MIGRACIÓN QUE LO REQUIERE:
-- db/migrate/20251204213314_add_trigram_index_to_packages_tracking_code.rb

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ------------------------------------------
-- VERIFICACIÓN DE INSTALACIÓN
-- ------------------------------------------
-- Este bloque verifica que la extensión se instaló correctamente
-- y muestra un mensaje en los logs de PostgreSQL.

DO $$
BEGIN
  -- Verificar si pg_trgm está en la lista de extensiones instaladas
  IF EXISTS (
    SELECT 1
    FROM pg_extension
    WHERE extname = 'pg_trgm'
  ) THEN
    -- ✓ Éxito: Mostrar mensaje de confirmación
    RAISE NOTICE '✓ Extensión pg_trgm habilitada correctamente';
    RAISE NOTICE '  Índices trigram disponibles para búsquedas rápidas';
  ELSE
    -- ✗ Error: La extensión no se pudo instalar
    RAISE EXCEPTION '✗ ERROR CRÍTICO: No se pudo instalar la extensión pg_trgm';
  END IF;
END $$;

-- ------------------------------------------
-- INFORMACIÓN ADICIONAL
-- ------------------------------------------
-- Para verificar manualmente que la extensión está instalada:
-- docker compose exec postgres psql -U postgres -d roraima_app_development -c '\dx'
--
-- Deberías ver una línea como:
-- pg_trgm | 1.6 | public | text similarity measurement and index searching based on trigrams
--
-- Para probar búsquedas con trigram:
-- SELECT * FROM packages WHERE tracking_code ILIKE '%PKG-861%';
-- (Esta query usará el índice GIN si existe)
--
-- ============================================
