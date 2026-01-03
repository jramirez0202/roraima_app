// Manejo de formulario de cambio de estado de paquetes (sin Stimulus)
// Compatible con Turbo Drive
document.addEventListener('turbo:load', function() {
  const form = document.getElementById('package-status-form');
  if (!form) return; // Solo ejecutar en la página del formulario

  const reasonField = document.getElementById('reason-field');
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
    const needsReschedulePhotos = status === 'rescheduled';
    const needsDeliveryPhotos = status === 'delivered';
    const needsCancelledPhotos = status === 'cancelled';

    console.log('needsReason:', needsReason, 'needsReschedulePhotos:', needsReschedulePhotos, 'needsDeliveryPhotos:', needsDeliveryPhotos, 'needsCancelledPhotos:', needsCancelledPhotos);

    // Mostrar/ocultar campos según el estado
    reasonField.style.display = needsReason ? 'block' : 'none';

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

  // Validar formulario antes de enviar
  function validateForm(event) {
    const status = getSelectedStatus();

    if (!status) {
      event.preventDefault();
      alert('Por favor, selecciona un nuevo estado.');
      return false;
    }

    // Validar motivo para estados que lo requieren
    if (status === 'return' || status === 'rescheduled' || status === 'cancelled') {
      const reason = document.getElementById('reason');
      if (reason && (!reason.value || reason.value.trim() === '')) {
        event.preventDefault();
        alert('Por favor, proporciona un motivo antes de continuar.');
        return false;
      }
    }

    // Validar fotos para estado "delivered"
    if (status === 'delivered') {
      const proofPhotos = document.getElementById('proof_photos');
      if (proofPhotos && proofPhotos.files.length === 0) {
        event.preventDefault();
        alert('⚠️ Debes seleccionar al menos 1 foto para marcar como entregado.');
        return false;
      }
      if (proofPhotos && proofPhotos.files.length > 4) {
        event.preventDefault();
        alert('⚠️ Máximo 4 fotos permitidas.');
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
