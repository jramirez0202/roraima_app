class BulkUpload < ApplicationRecord
  belongs_to :user
  has_many :packages, dependent: :nullify
  has_one_attached :file
  has_one_attached :labels_pdf

  enum status: {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }

  validates :file, presence: true
  validates :status, presence: true
  validate :file_format

  scope :recent, -> { order(created_at: :desc) }

  def success_rate
    return 0 if total_rows.zero?
    (successful_rows.to_f / total_rows * 100).round(2)
  end

  def formatted_errors
    return [] if error_details.blank?

    error_details.map do |error|
      "Fila #{error['row']}: #{error['column']} - #{error['error']}"
    end
  end

  def progress_percentage
    return 0 if total_rows.nil? || total_rows.zero?
    ((processed_count.to_f / total_rows) * 100).round(2)
  end

  def in_progress?
    processing?
  end

  def broadcast_progress
    Turbo::StreamsChannel.broadcast_replace_to(
      "bulk_upload_#{id}",
      target: "bulk_upload_progress",
      partial: "customers/bulk_uploads/progress",
      locals: { bulk_upload: self }
    )
  end

  def broadcast_completion
    Turbo::StreamsChannel.broadcast_replace_to(
      "bulk_upload_#{id}",
      target: "bulk_upload_progress",
      partial: "customers/bulk_uploads/completed",
      locals: { bulk_upload: self }
    )
  end

  private

  def file_format
    return unless file.attached?

    unless file.content_type.in?(['text/csv', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])
      errors.add(:file, 'debe ser un archivo CSV o XLSX')
    end
  end
end
