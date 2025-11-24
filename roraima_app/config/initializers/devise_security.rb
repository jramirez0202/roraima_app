# Security configuration for Devise
# Prevents direct URL access to disabled routes (registrations and passwords)

Rails.application.config.to_prepare do
  Devise::RegistrationsController.class_eval do
    before_action :block_registration

    private

    def block_registration
      redirect_to root_path, alert: 'El registro de usuarios está deshabilitado. Contacte al administrador.'
    end
  end

  Devise::PasswordsController.class_eval do
    before_action :block_password_recovery

    private

    def block_password_recovery
      redirect_to root_path, alert: 'La recuperación de contraseña está deshabilitada. Contacte al administrador.'
    end
  end
end
