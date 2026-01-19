require "test_helper"

class Admin::UsersControllerCreateTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
  end

  test "crear driver con todos los campos desde formulario" do
    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: {
          role: "driver",
          email: "driver_test@example.com",
          password: "password123",
          password_confirmation: "password123",
          rut: "18.888.888-8",
          phone: "+56987654332",
          active: "1"
        }
      }
    end

    driver = User.last
    puts "\n=== DRIVER CREADO ==="
    puts "Email: #{driver.email}"
    puts "RUT: #{driver.rut.inspect}"
    puts "Phone: #{driver.phone.inspect}"
    puts "Role: #{driver.role}"
    
    assert_equal "driver_test@example.com", driver.email
    assert_equal "18.888.888-8", driver.rut, "RUT debería guardarse"
    assert_equal "+56987654332", driver.phone, "Phone debería guardarse"
    assert_equal "driver", driver.role
  end

  test "crear customer con todos los campos desde formulario" do
    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: {
          role: "customer",
          email: "customer_test@example.com",
          password: "password123",
          password_confirmation: "password123",
          rut: "19.999.999-9",
          phone: "+56987654333",
          company: "Test Company SA",
          delivery_charge: "6000",
          active: "1"
        }
      }
    end

    customer = User.last
    puts "\n=== CUSTOMER CREADO ==="
    puts "Email: #{customer.email}"
    puts "RUT: #{customer.rut.inspect}"
    puts "Phone: #{customer.phone.inspect}"
    puts "Company: #{customer.company.inspect}"
    puts "Delivery charge: #{customer.delivery_charge}"
    puts "Role: #{customer.role}"
    
    assert_equal "customer_test@example.com", customer.email
    assert_equal "19.999.999-9", customer.rut, "RUT debería guardarse"
    assert_equal "+56987654333", customer.phone, "Phone debería guardarse"
    assert_equal "Test Company SA", customer.company, "Company debería guardarse"
    assert_equal 6000.0, customer.delivery_charge
    assert_equal "customer", customer.role
  end
end
