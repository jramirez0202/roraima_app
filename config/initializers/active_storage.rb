# ActiveStorage Configuration
# This file configures ActiveStorage behavior for file uploads and URLs

Rails.application.config.after_initialize do
  # Presigned URL expiration (default is 5 minutes)
  # Increase to 1 hour for better user experience with large files
  ActiveStorage.service_urls_expire_in = 1.hour

  # Force Content-Type for images to display inline in browser
  # By default, Rails serves these as binary (downloads instead of displaying)
  ActiveStorage.content_types_to_serve_as_binary -= ['image/png', 'image/gif', 'image/jpeg', 'image/jpg']

  # NOTE: replace_on_assign_to_many is deprecated in Rails 7.1+
  # The behavior is now the default, so this line is no longer needed
  # ActiveStorage.replace_on_assign_to_many = true
end
