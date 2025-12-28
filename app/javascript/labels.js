// JavaScript para manejo de selección de paquetes y generación de etiquetas
console.log("📦 JS de etiquetas cargado correctamente con Turbo");

document.addEventListener("turbo:load", function () {
  const selectAllCheckbox = document.getElementById("select-all");
  const packageCheckboxes = document.querySelectorAll(".package-checkbox");
  const generateBtn = document.getElementById("generate-labels-btn");
  const form = document.getElementById("labels-form");

  if (!selectAllCheckbox || !generateBtn || !form) {
    return; // Página sin elementos de etiquetas, salir silenciosamente
  }

  // Funcionalidad de seleccionar todos
  selectAllCheckbox.addEventListener("change", function () {
    packageCheckboxes.forEach((checkbox) => {
      checkbox.checked = this.checked;
    });
    toggleButton();
  });

  // Listeners para checkboxes individuales
  packageCheckboxes.forEach((checkbox) => {
    checkbox.addEventListener("change", function () {
      updateSelectAllState();
      toggleButton();
    });
  });

  function toggleButton() {
    const anyChecked = Array.from(packageCheckboxes).some((cb) => cb.checked);
    generateBtn.classList.toggle("hidden", !anyChecked);
  }

  function updateSelectAllState() {
    const allChecked = Array.from(packageCheckboxes).every((cb) => cb.checked);
    const someChecked = Array.from(packageCheckboxes).some((cb) => cb.checked);

    selectAllCheckbox.checked = allChecked;
    selectAllCheckbox.indeterminate = someChecked && !allChecked;
  }

  // Generar etiquetas
  generateBtn.addEventListener("click", async function (e) {
    e.preventDefault();

    const checkedBoxes = Array.from(packageCheckboxes).filter((cb) => cb.checked);

    if (checkedBoxes.length === 0) {
      alert("Por favor selecciona al menos un paquete");
      return;
    }

    if (checkedBoxes.length > 50) {
      if (!confirm(`Has seleccionado ${checkedBoxes.length} paquetes. ¿Continuar?`)) {
        return;
      }
    }

    generateBtn.disabled = true;
    const originalText = generateBtn.innerHTML;
    generateBtn.innerHTML =
      '<svg class="animate-spin h-4 w-4 mr-2 inline" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>Generando...';

    try {
      const formData = new FormData();
      const csrfToken = document.querySelector("meta[name='csrf-token']").content;

      formData.append("authenticity_token", csrfToken);

      checkedBoxes.forEach((cb) => {
        formData.append("package_ids[]", cb.value);
      });

      const response = await fetch(form.action, {
        method: "POST",
        body: formData,
        headers: { Accept: "application/pdf" },
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText);
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);

      const newWindow = window.open(url, "_blank");
      if (!newWindow) alert("Activa las ventanas emergentes");

      setTimeout(() => {
        window.URL.revokeObjectURL(url);
      }, 100);
    } catch (error) {
      console.error("Error generando etiquetas:", error);
      alert("Hubo un error al generar las etiquetas.");
    } finally {
      generateBtn.disabled = false;
      generateBtn.innerHTML = originalText;
    }
  });
});
