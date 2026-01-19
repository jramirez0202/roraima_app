FactoryBot.define do
  factory :bulk_upload do
    association :user
    status { :pending }
    total_rows { 0 }
    successful_rows { 0 }
    failed_rows { 0 }
    error_details { [] }

    # Trait for bulk upload with attached CSV file
    trait :with_csv do
      after(:build) do |bulk_upload|
        file_content = File.read(Rails.root.join('test', 'fixtures', 'files', 'valid_packages.csv'))
        bulk_upload.file.attach(
          io: StringIO.new(file_content),
          filename: 'valid_packages.csv',
          content_type: 'text/csv'
        )
      end
    end

    # Trait for bulk upload with attached XLSX file
    trait :with_xlsx do
      after(:build) do |bulk_upload|
        file_content = File.read(Rails.root.join('test', 'fixtures', 'files', 'valid_packages.xlsx'))
        bulk_upload.file.attach(
          io: StringIO.new(file_content),
          filename: 'valid_packages.xlsx',
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
      end
    end

    # Trait for bulk upload with invalid CSV
    trait :with_invalid_csv do
      after(:build) do |bulk_upload|
        file_content = File.read(Rails.root.join('test', 'fixtures', 'files', 'invalid_packages.csv'))
        bulk_upload.file.attach(
          io: StringIO.new(file_content),
          filename: 'invalid_packages.csv',
          content_type: 'text/csv'
        )
      end
    end

    # Trait for bulk upload with missing headers
    trait :with_missing_headers do
      after(:build) do |bulk_upload|
        file_content = File.read(Rails.root.join('test', 'fixtures', 'files', 'missing_headers.csv'))
        bulk_upload.file.attach(
          io: StringIO.new(file_content),
          filename: 'missing_headers.csv',
          content_type: 'text/csv'
        )
      end
    end

    # Trait for processing status
    trait :processing do
      status { :processing }
    end

    # Trait for completed status
    trait :completed do
      status { :completed }
      total_rows { 3 }
      successful_rows { 3 }
      failed_rows { 0 }
      processed_at { Time.current }
    end

    # Trait for completed with errors
    trait :completed_with_errors do
      status { :completed }
      total_rows { 5 }
      successful_rows { 3 }
      failed_rows { 2 }
      error_details do
        [
          { row: 2, column: 'TELÉFONO', value: '123', error: 'formato inválido después de transformación: 123' },
          { row: 4, column: 'COMUNA', value: 'NoExiste', error: 'no existe en el sistema' }
        ]
      end
      processed_at { Time.current }
    end

    # Trait for failed status
    trait :failed do
      status { :failed }
      total_rows { 0 }
      successful_rows { 0 }
      failed_rows { 0 }
      error_details do
        [
          { row: 0, column: 'estructura', value: '', error: 'El archivo no tiene las columnas requeridas' }
        ]
      end
      processed_at { Time.current }
    end
  end
end
