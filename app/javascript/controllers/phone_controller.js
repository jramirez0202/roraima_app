import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="phone"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Si el campo está vacío al cargar, insertar el prefijo
    if (!this.inputTarget.value) {
      this.inputTarget.value = "+569"
    }

    // Agregar clase para feedback visual
    this.validateFormat()

    // Limpiar el campo antes de enviar el formulario si solo contiene el prefijo
    this.element.closest('form').addEventListener('submit', this.handleSubmit.bind(this))
  }

  disconnect() {
    // Limpiar el event listener al desconectar
    const form = this.element.closest('form')
    if (form) {
      form.removeEventListener('submit', this.handleSubmit.bind(this))
    }
  }

  handleSubmit(event) {
    const value = this.inputTarget.value.trim()
    // Si el teléfono no está completo (no cumple el formato +569XXXXXXXX), limpiar el campo
    const isComplete = /^\+569\d{8}$/.test(value)
    if (!isComplete) {
      this.inputTarget.value = ""
    }
  }

  // Método que se ejecuta cuando el usuario hace focus en el campo
  focus(event) {
    const input = event.target

    // Si está vacío, insertar prefijo
    if (!input.value) {
      input.value = "+569"
    }

    // Mover cursor al final
    setTimeout(() => {
      input.setSelectionRange(input.value.length, input.value.length)
    }, 0)
  }

  // Método que se ejecuta mientras el usuario escribe
  input(event) {
    const input = event.target
    let value = input.value

    // Siempre debe empezar con +569
    if (!value.startsWith("+569")) {
      // Si el usuario intenta borrar el prefijo, restaurarlo
      value = "+569"
    }

    // Remover caracteres no numéricos después del prefijo
    const prefix = "+569"
    const numbers = value.slice(4).replace(/\D/g, "")

    // Limitar a 8 dígitos después del prefijo
    const limitedNumbers = numbers.slice(0, 8)

    // Actualizar el valor
    input.value = prefix + limitedNumbers

    // Validar formato
    this.validateFormat()
  }

  // Método que valida el formato y aplica clases CSS
  validateFormat() {
    const input = this.inputTarget
    const value = input.value

    // Expresión regular: +569 seguido de exactamente 8 dígitos
    const isValid = /^\+569\d{8}$/.test(value)

    if (value === "+569") {
      // Estado neutral (aún escribiendo)
      input.classList.remove("border-red-500", "border-green-500")
      input.classList.add("border-gray-300")
    } else if (isValid) {
      // Válido: borde verde
      input.classList.remove("border-red-500", "border-gray-300")
      input.classList.add("border-green-500")
    } else {
      // Inválido: borde rojo
      input.classList.remove("border-green-500", "border-gray-300")
      input.classList.add("border-red-500")
    }
  }

  // Prevenir que el usuario borre el prefijo con teclas de borrado
  keydown(event) {
    const input = event.target
    const cursorPosition = input.selectionStart

    // Si intenta borrar dentro del prefijo (+569), prevenir
    if ((event.key === "Backspace" || event.key === "Delete") && cursorPosition <= 4) {
      event.preventDefault()
      // Mover cursor después del prefijo
      input.setSelectionRange(4, 4)
    }
  }

  // Prevenir copiar/pegar texto que rompa el formato
  paste(event) {
    event.preventDefault()

    // Obtener el texto pegado
    const pastedText = (event.clipboardData || window.clipboardData).getData('text')

    // Extraer solo números del texto pegado
    const numbers = pastedText.replace(/\D/g, "")

    // Si los números empiezan con 569, usarlos directamente
    let digitsToUse = numbers
    if (numbers.startsWith("569")) {
      digitsToUse = numbers.slice(3, 11) // Tomar los siguientes 8 dígitos
    } else {
      digitsToUse = numbers.slice(0, 8)
    }

    // Actualizar el campo
    this.inputTarget.value = "+569" + digitsToUse

    // Validar
    this.validateFormat()
  }
}
