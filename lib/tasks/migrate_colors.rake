namespace :colors do
  desc "Encuentra colores Tailwind hardcodeados en las vistas"
  task find_hardcoded: :environment do
    puts "\n🔍 Buscando colores hardcodeados en las vistas...\n\n"

    # Patrones de colores Tailwind comunes
    patterns = {
      'bg-indigo-600' => 'btn-primary o bg-[var(--color-primary)]',
      'bg-indigo-700' => 'hover:bg-[var(--color-primary-hover)]',
      'bg-green-600' => 'btn-success o bg-[var(--color-success)]',
      'bg-green-700' => 'hover:bg-[var(--color-success-hover)]',
      'bg-yellow-500' => 'badge-pending o bg-[var(--color-status-pending)]',
      'bg-blue-500' => 'badge-warehouse o bg-[var(--color-status-warehouse)]',
      'bg-blue-600' => 'badge-transit o bg-[var(--color-status-transit)]',
      'bg-green-500' => 'badge-delivered o bg-[var(--color-status-delivered)]',
      'bg-amber-500' => 'badge-rescheduled o bg-[var(--color-status-rescheduled)]',
      'bg-orange-600' => 'badge-return o bg-[var(--color-status-return)]',
      'bg-red-600' => 'badge-cancelled o bg-[var(--color-status-cancelled)]',
      'bg-slate-800' => 'sidebar-admin o sidebar-customer o bg-[var(--color-admin-bg)]',
      'bg-teal-700' => 'sidebar-driver o bg-[var(--color-driver-bg)]'
    }

    view_paths = [
      Rails.root.join('app', 'views'),
      Rails.root.join('app', 'components')
    ]

    total_found = 0

    view_paths.each do |path|
      next unless Dir.exist?(path)

      Dir.glob("#{path}/**/*.html.erb").each do |file|
        content = File.read(file)
        file_matches = []

        patterns.each do |pattern, suggestion|
          if content.include?(pattern)
            file_matches << { pattern: pattern, suggestion: suggestion }
          end
        end

        if file_matches.any?
          relative_path = file.gsub(Rails.root.to_s + '/', '')
          puts "📄 #{relative_path}"

          file_matches.each do |match|
            puts "   ❌ Encontrado: #{match[:pattern]}"
            puts "   ✅ Sugerencia: #{match[:suggestion]}"
            puts ""
          end

          total_found += file_matches.size
        end
      end
    end

    puts "\n" + "="*60
    puts "Total de colores hardcodeados encontrados: #{total_found}"
    puts "="*60
    puts "\n📖 Para más información, lee: app/assets/stylesheets/README_COLORS.md\n\n"
  end

  desc "Muestra ejemplos de migración de colores"
  task examples: :environment do
    puts "\n📚 EJEMPLOS DE MIGRACIÓN DE COLORES\n"
    puts "="*60
    puts "\n"

    puts "1️⃣  BOTONES PRINCIPALES"
    puts "-"*60
    puts "❌ ANTES:"
    puts '   class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2"'
    puts "\n✅ DESPUÉS (Opción A - Clase predefinida):"
    puts '   class="btn-primary px-4 py-2"'
    puts "\n✅ DESPUÉS (Opción B - Variable CSS):"
    puts '   class="bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)] text-white px-4 py-2"'
    puts "\n"

    puts "2️⃣  BADGES DE ESTADO"
    puts "-"*60
    puts "❌ ANTES:"
    puts '   <span class="bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs">'
    puts "\n✅ DESPUÉS:"
    puts '   <span class="badge-delivered">'
    puts "\n"

    puts "3️⃣  SIDEBAR POR ROL"
    puts "-"*60
    puts "❌ ANTES:"
    puts '   <div class="<%= current_user.admin? ? \'bg-slate-800\' : \'bg-teal-700\' %>">'
    puts "\n✅ DESPUÉS:"
    puts '   <div class="sidebar-<%= current_user.role %>">'
    puts "\n"

    puts "4️⃣  COLORES PERSONALIZADOS"
    puts "-"*60
    puts "✅ En tu CSS:"
    puts '   .mi-clase {'
    puts '     background-color: var(--color-primary);'
    puts '     color: white;'
    puts '   }'
    puts "\n✅ En HTML inline:"
    puts '   <div style="background-color: var(--color-success)">'
    puts "\n"

    puts "="*60
    puts "📖 Más info: app/assets/stylesheets/README_COLORS.md"
    puts "="*60
    puts "\n"
  end

  desc "Lista todas las variables de color disponibles"
  task list: :environment do
    puts "\n🎨 VARIABLES DE COLOR DISPONIBLES\n"
    puts "="*60
    puts "\n"

    categories = {
      "COLORES PRIMARIOS" => [
        "--color-primary",
        "--color-primary-hover",
        "--color-success",
        "--color-success-hover"
      ],
      "ESTADOS DE PAQUETES" => [
        "--color-status-pending",
        "--color-status-warehouse",
        "--color-status-transit",
        "--color-status-delivered",
        "--color-status-rescheduled",
        "--color-status-return",
        "--color-status-cancelled"
      ],
      "COLORES DE ROLES" => [
        "--color-admin-bg",
        "--color-customer-bg",
        "--color-driver-bg"
      ],
      "COLORES DE UI" => [
        "--color-text-primary",
        "--color-text-secondary",
        "--color-bg-primary",
        "--color-border-light"
      ],
      "ALERTAS" => [
        "--color-info",
        "--color-warning",
        "--color-error",
        "--color-success-notification"
      ]
    }

    categories.each do |category, vars|
      puts "#{category}:"
      puts "-"*60
      vars.each do |var|
        puts "  • var(#{var})"
      end
      puts "\n"
    end

    puts "="*60
    puts "💡 Uso: style=\"background-color: var(--color-primary)\""
    puts "💡 O en CSS: background-color: var(--color-primary);"
    puts "="*60
    puts "\n"
  end
end
