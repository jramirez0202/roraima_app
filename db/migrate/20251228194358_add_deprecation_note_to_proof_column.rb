class AddDeprecationNoteToProofColumn < ActiveRecord::Migration[7.1]
  def change
    # Agregar comentario de deprecación a la columna proof
    # Esta columna almacenaba JSON con imágenes base64 (ineficiente)
    # Nueva implementación usa Active Storage: has_many_attached :proof_photos
    change_column_comment :packages, :proof,
      from: nil,
      to: "DEPRECATED: Use proof_photos Active Storage attachment instead. This column stored base64 JSON (inefficient). Will be removed in future version after data migration."
  end
end
