// Manejo de formulario de cambio de estado de paquetes (sin Stimulus)
// Compatible con Turbo Drive
document.addEventListener('turbo:load', function() {
  const form = document.getElementById('package-status-form');
  if (!form) return; // Solo ejecutar en la página del formulario

  const statusSelect = document.getElementById('new_status');
  const reasonField = document.getElementById('reason-field');
  const proofField = document.getElementById('proof-field');
  const reschedulePhotosField = document.getElementById('reschedule-photos-field');
  const photoInput = document.getElementById('photo-input');
  const photosContainer = document.getElementById('photos-container');
  const compressionStatus = document.getElementById('compression-status');
  const proofData = document.getElementById('proof-data');

  if (!statusSelect || !reasonField) return;

  let compressedPhotos = [];
  const MAX_PHOTOS = 4;

  console.log('📦 Package form script loaded');

  // Toggle de campos al cambiar el estado
  function toggleFields() {
    const status = statusSelect.value;
    console.log('🔄 toggleFields called, status:', status);

    const needsReason = ['return', 'rescheduled'].includes(status);
    const needsProof = status === 'delivered';
    const needsReschedulePhotos = status === 'rescheduled';

    console.log('needsReason:', needsReason, 'needsProof:', needsProof, 'needsReschedulePhotos:', needsReschedulePhotos);

    reasonField.style.display = needsReason ? 'block' : 'none';
    if (proofField) {
      proofField.style.display = needsProof ? 'block' : 'none';
    }
    if (reschedulePhotosField) {
      reschedulePhotosField.style.display = needsReschedulePhotos ? 'block' : 'none';
    }

    // Actualizar required
    const reasonTextarea = document.getElementById('reason');
    if (reasonTextarea) {
      reasonTextarea.required = needsReason;
    }
  }

  // Manejar selección de fotos
  function handlePhotoInput(event) {
    const files = Array.from(event.target.files);

    if (compressedPhotos.length + files.length > MAX_PHOTOS) {
      alert(`Solo puedes subir un máximo de ${MAX_PHOTOS} fotos. Actualmente tienes ${compressedPhotos.length} foto(s).`);
      photoInput.value = '';
      return;
    }

    if (files.length > 0) {
      compressionStatus.style.display = 'block';

      let processedCount = 0;
      files.forEach((file) => {
        compressImage(file, (compressedDataUrl, originalSize, compressedSize) => {
          compressedPhotos.push(compressedDataUrl);
          addPhotoPreview(compressedDataUrl, compressedSize, compressedPhotos.length - 1);

          processedCount++;
          if (processedCount === files.length) {
            compressionStatus.style.display = 'none';
            updateProofData();
            photoInput.value = '';
          }
        });
      });
    }
  }

  // Comprimir imagen
  function compressImage(file, callback) {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();

      img.onload = () => {
        const MAX_WIDTH = 800;
        const MAX_HEIGHT = 800;
        const QUALITY = 0.6;

        let width = img.width;
        let height = img.height;

        if (width > height) {
          if (width > MAX_WIDTH) {
            height *= MAX_WIDTH / width;
            width = MAX_WIDTH;
          }
        } else {
          if (height > MAX_HEIGHT) {
            width *= MAX_HEIGHT / height;
            height = MAX_HEIGHT;
          }
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, width, height);

        const compressedDataUrl = canvas.toDataURL('image/jpeg', QUALITY);
        const originalSize = Math.round(e.target.result.length * 0.75 / 1024);
        const compressedSize = Math.round(compressedDataUrl.length * 0.75 / 1024);

        console.log(`📸 Imagen comprimida: ${originalSize}KB → ${compressedSize}KB`);

        callback(compressedDataUrl, originalSize, compressedSize);
      };

      img.src = e.target.result;
    };

    reader.readAsDataURL(file);
  }

  // Agregar preview de foto
  function addPhotoPreview(dataUrl, sizeKB, index) {
    const photoDiv = document.createElement('div');
    photoDiv.className = 'relative';
    photoDiv.dataset.photoIndex = index;
    photoDiv.innerHTML = `
      <img src="${dataUrl}" class="w-full h-32 object-cover rounded border border-gray-200">
      <button type="button" data-photo-index="${index}"
              class="photo-remove-btn absolute top-1 right-1 bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center hover:bg-red-700">
        ×
      </button>
      <p class="text-xs text-green-600 mt-1">${sizeKB}KB</p>
    `;
    photosContainer.appendChild(photoDiv);
  }

  // Eliminar foto
  function removePhoto(index) {
    console.log('Removing photo at index:', index);
    compressedPhotos.splice(index, 1);
    refreshPhotosPreviews();
    updateProofData();
  }

  // Refrescar previews
  function refreshPhotosPreviews() {
    photosContainer.innerHTML = '';
    compressedPhotos.forEach((photo, idx) => {
      const sizeKB = Math.round(photo.length * 0.75 / 1024);
      addPhotoPreview(photo, sizeKB, idx);
    });
  }

  // Actualizar campo hidden
  function updateProofData() {
    proofData.value = JSON.stringify(compressedPhotos);
    console.log('Updated proof data:', compressedPhotos.length, 'photos');
  }

  // Validar formulario antes de enviar
  function validateForm(event) {
    const status = statusSelect.value;

    if (!status) {
      event.preventDefault();
      alert('Por favor, selecciona un nuevo estado.');
      return false;
    }

    if (status === 'delivered') {
      if (compressedPhotos.length === 0) {
        event.preventDefault();
        alert('Por favor, proporciona al menos una foto de evidencia antes de continuar.');
        return false;
      }
    }

    if (status === 'return' || status === 'rescheduled') {
      const reason = document.getElementById('reason').value;
      if (!reason || reason.trim() === '') {
        event.preventDefault();
        alert('Por favor, proporciona un motivo antes de continuar.');
        return false;
      }
    }

    return true;
  }

  // Event listeners
  statusSelect.addEventListener('change', toggleFields);
  photoInput.addEventListener('change', handlePhotoInput);
  form.addEventListener('submit', validateForm);

  // Event delegation para botones de eliminar foto
  photosContainer.addEventListener('click', function(e) {
    if (e.target.classList.contains('photo-remove-btn') || e.target.closest('.photo-remove-btn')) {
      const btn = e.target.classList.contains('photo-remove-btn') ? e.target : e.target.closest('.photo-remove-btn');
      const index = parseInt(btn.dataset.photoIndex);
      removePhoto(index);
    }
  });

  // Inicializar
  toggleFields();
});
