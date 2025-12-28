# ActiveStorage Configuration
# This file configures ActiveStorage behavior for file uploads and URLs

Rails.application.config.after_initialize do
  # Presigned URL expiration (default is 5 minutes)
  # Increase to 1 hour for better user experience with large files
  ActiveStorage.service_urls_expire_in = 1.hour

  # Force Content-Type for images to display inline in browser
  # By default, Rails serves these as binary (downloads instead of displaying)
  ActiveStorage.content_types_to_serve_as_binary -= ['image/png', 'image/gif', 'image/jpeg', 'image/jpg']

  # Replace attachments when using has_many_attached
  # When reassigning to a has_many_attached, this will replace existing attachments
  # rather than appending to them
  ActiveStorage.replace_on_assign_to_many = true
end
