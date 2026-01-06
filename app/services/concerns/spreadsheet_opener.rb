# app/services/concerns/spreadsheet_opener.rb
module SpreadsheetOpener
  extend self  # esto hace que todos los métodos sean de módulo directamente

  def open_from_attachment(file_attachment)
    raise "No se recibió archivo adjunto" unless file_attachment.attached?

    tempfile = Tempfile.new([file_attachment.filename.base, file_attachment.filename.extension_with_delimiter])
    tempfile.binmode
    tempfile.write(file_attachment.download)
    tempfile.rewind

    ext = file_attachment.filename.extension.to_s.downcase
    Roo::Spreadsheet.open(tempfile.path, extension: ext)
  ensure
    # Tempfile se cierra automáticamente al salir del bloque
  end
end
