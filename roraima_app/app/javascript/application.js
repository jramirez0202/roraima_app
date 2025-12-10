// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Importar módulo de etiquetas
import "./labels"

// Importar formulario de paquetes (JavaScript vanilla)
import "./package_form"

console.log("App cargada - Turbo Rails + Stimulus habilitados (versión local)")
import "./channels"
