// Manejo de formulario de cambio de estado de paquetes (sin Stimulus)
// Compatible con Turbo Drive
document.addEventListener('turbo:load', function() {
  const form = document.getElementById('package-status-form');
  if (!form) return; // Solo ejecutar en la página del formulario

  const reasonField = document.getElementById('reason-field');
  const receiverFields = document.getElementById('receiver-fields');
  const reschedulePhotosField = document.getElementById('reschedule-photos-field');
  const deliveryPhotosField = document.getElementById('delivery-photos-field');
  const cancelledPhotosField = document.getElementById('cancelled-photos-field');

  if (!reasonField) return;

  console.log('📦 Package form script loaded');

  // Obtener el estado seleccionado de los radio buttons
  function getSelectedStatus() {
    const radioButton = document.querySelector('input[name="new_status"]:checked');
    return radioButton ? radioButton.value : '';
  }

  // Toggle de campos al cambiar el estado
  function toggleFields() {
    const status = getSelectedStatus();
    console.log('🔄 toggleFields called, status:', status);

    const needsReason = ['return', 'rescheduled', 'cancelled'].includes(status);
    const needsReceiverFields = status === 'delivered';
    const needsReschedulePhotos = status === 'rescheduled';
    const needsDeliveryPhotos = status === 'delivered';
    const needsCancelledPhotos = status === 'cancelled';

    console.log('needsReason:', needsReason, 'needsReceiverFields:', needsReceiverFields, 'needsReschedulePhotos:', needsReschedulePhotos, 'needsDeliveryPhotos:', needsDeliveryPhotos, 'needsCancelledPhotos:', needsCancelledPhotos);

    // Mostrar/ocultar campos según el estado
    reasonField.style.display = needsReason ? 'block' : 'none';

    // Mostrar/ocultar campos del receptor para entregado
    if (receiverFields) {
      receiverFields.style.display = needsReceiverFields ? 'block' : 'none';
    }

    const submitBtn = document.getElementById('update-status-btn');

    // Manejo de fotos de reprogramación
    if (reschedulePhotosField) {
      reschedulePhotosField.style.display = needsReschedulePhotos ? 'block' : 'none';

      if (submitBtn && needsReschedulePhotos) {
        // Ocultar botón "Actualizar Estado", se usa el botón del controller Stimulus
        submitBtn.classList.add('hidden');

        // Mostrar botón de "Subir Fotos" del controller reschedule
        const uploadBtn = reschedulePhotosField.querySelector('[data-reschedule-photos-target="submit"]');
        if (uploadBtn) {
          uploadBtn.classList.remove('hidden');
        }
      }
    }

    // Manejo de fotos de entrega
    if (deliveryPhotosField) {
      deliveryPhotosField.style.display = needsDeliveryPhotos ? 'block' : 'none';

      if (submitBtn && needsDeliveryPhotos) {
        // Ocultar botón "Actualizar Estado", se usa el botón del controller Stimulus
        submitBtn.classList.add('hidden');

        // Mostrar botón de "Subir Fotos" del controller delivery
        const uploadBtn = deliveryPhotosField.querySelector('[data-delivery-photos-target="submit"]');
        if (uploadBtn) {
          uploadBtn.classList.remove('hidden');
        }
      }
    }

    // Manejo de fotos de cancelación
    if (cancelledPhotosField) {
      cancelledPhotosField.style.display = needsCancelledPhotos ? 'block' : 'none';

      if (submitBtn && needsCancelledPhotos) {
        // Ocultar botón "Actualizar Estado", se usa el botón del controller Stimulus
        submitBtn.classList.add('hidden');

        // Mostrar botón de "Subir Fotos" del controller cancelled
        const uploadBtn = cancelledPhotosField.querySelector('[data-cancelled-photos-target="submit"]');
        if (uploadBtn) {
          uploadBtn.classList.remove('hidden');
        }
      }
    }

    // Si NO necesita fotos, mostrar botón normal
    if (submitBtn && !needsDeliveryPhotos && !needsReschedulePhotos && !needsCancelledPhotos) {
      submitBtn.classList.remove('hidden');

      // Ocultar todos los botones de "Subir Fotos"
      const deliveryUploadBtn = deliveryPhotosField?.querySelector('[data-delivery-photos-target="submit"]');
      if (deliveryUploadBtn) {
        deliveryUploadBtn.classList.add('hidden');
      }

      const rescheduleUploadBtn = reschedulePhotosField?.querySelector('[data-reschedule-photos-target="submit"]');
      if (rescheduleUploadBtn) {
        rescheduleUploadBtn.classList.add('hidden');
      }

      const cancelledUploadBtn = cancelledPhotosField?.querySelector('[data-cancelled-photos-target="submit"]');
      if (cancelledUploadBtn) {
        cancelledUploadBtn.classList.add('hidden');
      }
    }

    // Actualizar required
    const reasonTextarea = document.getElementById('reason');
    if (reasonTextarea) {
      reasonTextarea.required = needsReason;
    }

    const receiverNameInput = document.getElementById('receiver_name');
    if (receiverNameInput) {
      receiverNameInput.required = needsReceiverFields;
    }
  }

  // Actualizar contador de fotos
  function updatePhotoCount() {
    const proofPhotosInput = document.getElementById('proof_photos');
    const photoCount = document.getElementById('photo-count');
    const photoCountNumber = document.getElementById('photo-count-number');

    if (proofPhotosInput && photoCount && photoCountNumber) {
      const count = proofPhotosInput.files.length;

      if (count > 0) {
        photoCountNumber.textContent = count;
        photoCount.classList.remove('hidden');

        // Cambiar color según cantidad
        if (count > 4) {
          photoCount.className = 'mt-2 text-sm text-red-600 font-medium';
        } else {
          photoCount.className = 'mt-2 text-sm text-green-600 font-medium';
        }
      } else {
        photoCount.classList.add('hidden');
      }
    }
  }

  // Función global para manejar cambio de estado desde radio buttons
  window.handleStatusChange = function(status) {
    console.log('📻 Status changed to:', status);
    toggleFields();
  };

  // Mostrar alerta estilo flash (sin refresh)
  function showFlashAlert(message, type = 'error') {
    // Remover alertas previas
    const existingAlert = document.querySelector('.flash-alert-dynamic')
    if (existingAlert) existingAlert.remove()

    const colors = {
      error: {
        bg: 'bg-red-50',
        border: 'border-red-500',
        text: 'text-red-800',
        icon: 'text-red-500'
      }
    }

    const color = colors[type] || colors.error

    const alertHTML = `
      <div class="flash-alert-dynamic mb-4 ${color.bg} border-l-4 ${color.border} p-4 rounded shadow-sm">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 ${color.icon}" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
            </svg>
          </div>
          <div class="ml-3 flex-1">
            <p class="text-sm font-medium ${color.text}">${message}</p>
          </div>
          <div class="ml-auto pl-3">
            <button type="button" class="inline-flex ${color.text} hover:${color.bg} rounded-md p-1.5 focus:outline-none" onclick="this.parentElement.parentElement.parentElement.remove()">
              <span class="sr-only">Cerrar</span>
              <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    `

    // Insertar antes del formulario de cambio de estado
    const formElement = document.getElementById('package-status-form')
    if (formElement) {
      formElement.insertAdjacentHTML('beforebegin', alertHTML)

      // Scroll suave a la alerta
      const alertElement = document.querySelector('.flash-alert-dynamic')
      if (alertElement) {
        alertElement.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }

      // Auto-ocultar después de 6 segundos
      setTimeout(() => {
        const alertToRemove = document.querySelector('.flash-alert-dynamic')
        if (alertToRemove) {
          alertToRemove.style.transition = 'opacity 0.3s ease-out'
          alertToRemove.style.opacity = '0'
          setTimeout(() => alertToRemove.remove(), 300)
        }
      }, 6000)
    }
  }

  // Validar formulario antes de enviar
  function validateForm(event) {
    const status = getSelectedStatus();

    if (!status) {
      event.preventDefault();
      showFlashAlert('Por favor, selecciona un nuevo estado.')
      return false;
    }

    // Validar motivo para estados que lo requieren
    if (status === 'return' || status === 'rescheduled' || status === 'cancelled') {
      const reason = document.getElementById('reason');
      if (reason && (!reason.value || reason.value.trim() === '')) {
        event.preventDefault();
        showFlashAlert('Se requiere un motivo para reprogramar por favor.')
        reason.focus()
        reason.scrollIntoView({ behavior: 'smooth', block: 'center' })
        return false;
      }
    }

    // Validar datos del receptor para estado "delivered"
    // Nota: La validación de fotos se hace en delivery_photos_controller.js
    if (status === 'delivered') {
      const receiverName = document.getElementById('receiver_name');
      if (receiverName && (!receiverName.value || receiverName.value.trim() === '')) {
        event.preventDefault();
        showFlashAlert('Se requiere el nombre del receptor para marcar como entregado por favor.')
        receiverName.focus()
        receiverName.scrollIntoView({ behavior: 'smooth', block: 'center' })
        return false;
      }
    }

    return true;
  }

  // Event listeners
  if (form) {
    form.addEventListener('submit', validateForm);
  }

  // Event listener para contador de fotos
  const proofPhotosInput = document.getElementById('proof_photos');
  if (proofPhotosInput) {
    proofPhotosInput.addEventListener('change', updatePhotoCount);
  }

  // Inicializar - toggle fields con el estado seleccionado por defecto (delivered)
  toggleFields();
});
