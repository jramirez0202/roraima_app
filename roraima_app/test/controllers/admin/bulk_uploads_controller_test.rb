require "test_helper"

class Admin::BulkUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @customer = create(:user, :customer, email: 'test@example.com')

    # Setup region and communes for synchronous validation
    @region = Region.find_or_create_by!(name: 'Región Metropolitana')
    @providencia = Commune.find_or_create_by!(name: 'Providencia', region: @region)
    @las_condes = Commune.find_or_create_by!(name: 'Las Condes', region: @region)
    @la_florida = Commune.find_or_create_by!(name: 'La Florida', region: @region)
  end

  # ====================
  # Authentication Tests
  # ====================
  test "should require authentication for new" do
    get new_admin_bulk_upload_path
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for create" do
    post admin_bulk_uploads_path, params: { bulk_upload: { file: nil } }
    assert_redirected_to new_user_session_path
  end

  # ====================
  # Authorization Tests
  # ====================
  test "should allow admin to access new" do
    sign_in @admin
    get new_admin_bulk_upload_path
    assert_response :success
  end

  test "should not allow customer to access new" do
    sign_in @customer
    get new_admin_bulk_upload_path
    assert_redirected_to root_path
    assert_equal "No tienes permisos para acceder a esta sección", flash[:alert]
  end

  test "should not allow customer to create bulk upload" do
    sign_in @customer

    file = fixture_file_upload('valid_packages.csv', 'text/csv')

    assert_no_difference 'BulkUpload.count' do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_redirected_to root_path
  end

  # ====================
  # GET #new Tests
  # ====================
  test "should get new as admin" do
    sign_in @admin
    get new_admin_bulk_upload_path

    assert_response :success
    assert_select 'h1', text: 'Carga Masiva de Paquetes'
    assert_select 'form[action=?]', admin_bulk_uploads_path
  end

  test "should show file upload field" do
    sign_in @admin
    get new_admin_bulk_upload_path

    assert_response :success
    assert_select 'input[type=file][name=?]', 'bulk_upload[file]'
  end

  test "should show instructions" do
    sign_in @admin
    get new_admin_bulk_upload_path

    assert_response :success
    assert_select 'div', text: /Instrucciones/
    assert_select 'div', text: /Formato Esperado/
  end

  test "should have link to download template" do
    sign_in @admin
    get new_admin_bulk_upload_path

    assert_response :success
    assert_select 'a[href=?]', '/plantilla_carga_masiva.csv'
  end

  # ====================
  # POST #create Tests
  # ====================
  test "should create bulk upload with valid file as admin" do
    sign_in @admin

    file = fixture_file_upload('valid_packages.csv', 'text/csv')

    assert_difference 'BulkUpload.count', 1 do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_redirected_to admin_packages_path
    assert_match /Carga iniciada/, flash[:notice]
  end

  test "should enqueue job on successful upload" do
    sign_in @admin

    file = fixture_file_upload('valid_packages.csv', 'text/csv')

    assert_enqueued_jobs 1, only: ProcessBulkPackageUploadJob do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end
  end

  test "should associate bulk upload with current user" do
    sign_in @admin

    file = fixture_file_upload('valid_packages.csv', 'text/csv')

    post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }

    bulk_upload = BulkUpload.last
    assert_equal @admin.id, bulk_upload.user_id
  end

  test "should show success message with monitoring link" do
    sign_in @admin

    file = fixture_file_upload('valid_packages.csv', 'text/csv')

    post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }

    assert_redirected_to admin_packages_path
    assert_includes flash[:notice], "Carga iniciada"
    assert_includes flash[:notice], "Puedes monitorear el progreso en /sidekiq"
  end

  test "should not create bulk upload without file" do
    sign_in @admin

    assert_no_difference 'BulkUpload.count' do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: nil } }
    end

    assert_response :unprocessable_entity
  end

  test "should show error message for invalid file" do
    sign_in @admin

    assert_no_difference 'BulkUpload.count' do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: nil } }
    end

    assert_response :unprocessable_entity
    assert_select 'div.bg-red-50', text: /Error/
  end

  test "should not create bulk upload with wrong file type" do
    sign_in @admin

    # Create a simple text file for testing
    File.write(Rails.root.join('test', 'fixtures', 'files', 'test.txt'), 'test content')

    file = fixture_file_upload('test.txt', 'text/plain')

    assert_no_difference 'BulkUpload.count' do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_response :unprocessable_entity

    # Cleanup
    File.delete(Rails.root.join('test', 'fixtures', 'files', 'test.txt'))
  end

  # ====================
  # Flash Messages Tests
  # ====================
  test "should show appropriate flash message on success" do
    sign_in @admin

    file = fixture_file_upload('valid_packages.csv', 'text/csv')

    post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }

    follow_redirect!

    assert_select 'div', text: /Carga iniciada/
  end

  # ====================
  # Validation Tests (New Synchronous Validation)
  # ====================
  test "should not create bulk upload when file has validation errors" do
    sign_in @admin

    file = fixture_file_upload('invalid_content.csv', 'text/csv')

    assert_no_difference 'BulkUpload.count' do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_response :unprocessable_entity
  end

  test "should not enqueue job when file has validation errors" do
    sign_in @admin

    file = fixture_file_upload('invalid_for_job.csv', 'text/csv')

    assert_no_enqueued_jobs only: ProcessBulkPackageUploadJob do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end
  end

  test "should show validation errors in view" do
    sign_in @admin

    file = fixture_file_upload('errors_display.csv', 'text/csv')

    post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }

    assert_response :unprocessable_entity
    assert_select 'div.bg-red-50', text: /Errores de Validación/
    assert_select 'li', text: /Fila 2/
  end

  test "should show alert message when validation fails" do
    sign_in @admin

    file = fixture_file_upload('alert_test.csv', 'text/csv')

    post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }

    assert_match /errores de validación/, flash[:alert]
  end

  test "should validate only first 100 rows and show warning" do
    sign_in @admin

    file = fixture_file_upload('150_rows.csv', 'text/csv')

    # Should still create BulkUpload since data is valid
    assert_difference 'BulkUpload.count', 1 do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle empty CSV file" do
    sign_in @admin

    # Create empty CSV
    File.write(Rails.root.join('test', 'fixtures', 'files', 'empty.csv'),
      "FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA\n")

    file = fixture_file_upload('empty.csv', 'text/csv')

    assert_difference 'BulkUpload.count', 1 do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    # Cleanup
    File.delete(Rails.root.join('test', 'fixtures', 'files', 'empty.csv'))
  end

  test "should handle large file" do
    sign_in @admin

    # Create a CSV with many rows
    content = "FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA\n"
    100.times do |i|
      content += "2025-01-15,ORDER-#{i},Cliente #{i},912345678,Dirección #{i},Providencia,Desc #{i},1000,NO,test@example.com\n"
    end

    File.write(Rails.root.join('test', 'fixtures', 'files', 'large.csv'), content)

    file = fixture_file_upload('large.csv', 'text/csv')

    assert_difference 'BulkUpload.count', 1 do
      post admin_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    # Cleanup
    File.delete(Rails.root.join('test', 'fixtures', 'files', 'large.csv'))
  end
end
