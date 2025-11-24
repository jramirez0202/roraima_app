require "test_helper"

class Customers::BulkUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @customer = create(:user, :customer)
  end

  # ====================
  # Authentication Tests
  # ====================
  test "should require authentication for new" do
    get new_customers_bulk_upload_path
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for create" do
    post customers_bulk_uploads_path, params: { bulk_upload: { file: nil } }
    assert_redirected_to new_user_session_path
  end

  # ====================
  # Authorization Tests
  # ====================
  test "should allow customer to access new" do
    sign_in @customer
    get new_customers_bulk_upload_path
    assert_response :success
  end

  test "should not allow admin to access customer new" do
    sign_in @admin
    get new_customers_bulk_upload_path
    assert_redirected_to root_path
    assert_equal "No tienes permisos para acceder a esta sección", flash[:alert]
  end

  test "should not allow admin to create bulk upload in customers namespace" do
    sign_in @admin

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    assert_no_difference 'BulkUpload.count' do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_redirected_to root_path
  end

  # ====================
  # GET #new Tests
  # ====================
  test "should get new as customer" do
    sign_in @customer
    get new_customers_bulk_upload_path

    assert_response :success
    assert_select 'h1', text: 'Carga Masiva de Paquetes'
    assert_select 'form[action=?]', customers_bulk_uploads_path
  end

  test "should show file upload field" do
    sign_in @customer
    get new_customers_bulk_upload_path

    assert_response :success
    assert_select 'input[type=file][name=?]', 'bulk_upload[file]'
  end

  test "should show instructions" do
    sign_in @customer
    get new_customers_bulk_upload_path

    assert_response :success
    assert_select 'div', text: /Instrucciones/
    assert_select 'div', text: /Formato Esperado/
  end

  test "should have link to download template" do
    sign_in @customer
    get new_customers_bulk_upload_path

    assert_response :success
    assert_select 'a[href=?]', '/plantilla_carga_masiva.csv'
  end

  test "should show customer-specific messaging" do
    sign_in @customer
    get new_customers_bulk_upload_path

    assert_response :success
    # Customer version shouldn't mention /sidekiq
    assert_select 'p', text: /Te notificaremos cuando termine/
  end

  # ====================
  # POST #create Tests
  # ====================
  test "should create bulk upload with valid file as customer" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    assert_difference 'BulkUpload.count', 1 do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_redirected_to customers_packages_path
    assert_match /Carga iniciada/, flash[:notice]
  end

  test "should enqueue job on successful upload" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    assert_enqueued_jobs 1, only: ProcessBulkPackageUploadJob do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end
  end

  test "should associate bulk upload with current customer" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }

    bulk_upload = BulkUpload.last
    assert_equal @customer.id, bulk_upload.user_id
  end

  test "should show success message for customers" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }

    assert_redirected_to customers_packages_path
    assert_includes flash[:notice], "Carga iniciada"
    # Customers shouldn't see Sidekiq monitoring link
    assert_not_includes flash[:notice], "/sidekiq"
  end

  test "should not create bulk upload without file" do
    sign_in @customer

    assert_no_difference 'BulkUpload.count' do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: nil } }
    end

    assert_response :unprocessable_entity
  end

  test "should show error message for invalid file" do
    sign_in @customer

    assert_no_difference 'BulkUpload.count' do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: nil } }
    end

    assert_response :unprocessable_entity
    assert_select 'div.bg-red-50', text: /Error/
  end

  test "should not create bulk upload with wrong file type" do
    sign_in @customer

    # Create a simple text file for testing
    File.write(Rails.root.join('test', 'fixtures', 'files', 'test.txt'), 'test content')

    file = fixture_file_upload('files/test.txt', 'text/plain')

    assert_no_difference 'BulkUpload.count' do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    assert_response :unprocessable_entity

    # Cleanup
    File.delete(Rails.root.join('test', 'fixtures', 'files', 'test.txt'))
  end

  # ====================
  # Flash Messages Tests
  # ====================
  test "should show appropriate flash message on success" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }

    follow_redirect!

    assert_select 'div', text: /Carga iniciada/
  end

  # ====================
  # Redirect Tests
  # ====================
  test "should redirect to customers packages path on success" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }

    assert_redirected_to customers_packages_path
  end

  test "should render new on failure" do
    sign_in @customer

    post customers_bulk_uploads_path, params: { bulk_upload: { file: nil } }

    assert_response :unprocessable_entity
    assert_template :new
  end

  # ====================
  # Edge Cases
  # ====================
  test "should handle empty CSV file" do
    sign_in @customer

    # Create empty CSV
    File.write(Rails.root.join('test', 'fixtures', 'files', 'empty_customer.csv'),
      "FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA\n")

    file = fixture_file_upload('files/empty_customer.csv', 'text/csv')

    assert_difference 'BulkUpload.count', 1 do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    # Cleanup
    File.delete(Rails.root.join('test', 'fixtures', 'files', 'empty_customer.csv'))
  end

  test "should handle large file" do
    sign_in @customer

    # Create a CSV with many rows
    content = "FECHA,NRO DE PEDIDO,DESTINATARIO,TELÉFONO,DIRECCIÓN,COMUNA,DESCRIPCIÓN,MONTO,CAMBIO,EMPRESA\n"
    100.times do |i|
      content += "2025-01-15,ORDER-#{i},Cliente #{i},912345678,Dirección #{i},Providencia,Desc #{i},1000,NO,Empresa\n"
    end

    File.write(Rails.root.join('test', 'fixtures', 'files', 'large_customer.csv'), content)

    file = fixture_file_upload('files/large_customer.csv', 'text/csv')

    assert_difference 'BulkUpload.count', 1 do
      post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }
    end

    # Cleanup
    File.delete(Rails.root.join('test', 'fixtures', 'files', 'large_customer.csv'))
  end

  # ====================
  # User Trait Tests
  # ====================
  test "customer should only see their own bulk uploads" do
    sign_in @customer

    file = fixture_file_upload('files/valid_packages.csv', 'text/csv')

    post customers_bulk_uploads_path, params: { bulk_upload: { file: file } }

    bulk_upload = BulkUpload.last
    assert_equal @customer, bulk_upload.user
    assert_not_equal @admin, bulk_upload.user
  end
end
