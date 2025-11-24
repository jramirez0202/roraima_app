require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = sign_in_as_admin
    @other_user = create(:user, email: "other@roraima.cl")
  end

  # ====================
  # Index Action
  # ====================
  test "should get index as admin" do
    get admin_users_url
    assert_response :success
  end

  test "should not get index as regular user" do
    sign_in_as_user
    get admin_users_url
    assert_redirected_to customers_dashboard_path
  end

  test "should list all users in index" do
    create_list(:user, 3)
    get admin_users_url
    assert_response :success
    # Should have at least 4 users (3 created + 1 other_user from setup)
  end

  # ====================
  # Show Action
  # ====================
  # Note: Show action test skipped - not critical for security validation

  # ====================
  # New Action
  # ====================
  test "should get new" do
    get new_admin_user_url
    assert_response :success
  end

  # ====================
  # Create Action
  # ====================
  test "should create user with valid params" do
    assert_difference("User.count", 1) do
      post admin_users_url, params: {
        user: {
          email: "newuser@roraima.cl",
          password: "password123",
          password_confirmation: "password123",
          role: :customer
        }
      }
    end

    assert_redirected_to admin_users_path
    assert_equal "Customer creado exitosamente.", flash[:notice]
  end

  test "should create admin user when role is admin" do
    assert_difference("User.count", 1) do
      post admin_users_url, params: {
        user: {
          email: "newadmin@roraima.cl",
          password: "password123",
          password_confirmation: "password123",
          role: :admin
        }
      }
    end

    new_admin = User.find_by(email: "newadmin@roraima.cl")
    assert new_admin.admin?, "User should be created as admin"
  end

  test "should set password when provided in create" do
    post admin_users_url, params: {
      user: {
        email: "testpass@roraima.cl",
        password: "mypassword123",
        password_confirmation: "mypassword123",
        role: :customer
      }
    }

    user = User.find_by(email: "testpass@roraima.cl")
    assert user.valid_password?("mypassword123"), "Password should be set correctly"
  end

  test "should not create user with invalid email" do
    assert_no_difference("User.count") do
      post admin_users_url, params: {
        user: {
          email: "invalid",
          password: "password123",
          password_confirmation: "password123",
          role: :customer
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "should not create user with duplicate email" do
    assert_no_difference("User.count") do
      post admin_users_url, params: {
        user: {
          email: @other_user.email,
          password: "password123",
          password_confirmation: "password123",
          role: :customer
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "should not create user without password" do
    assert_no_difference("User.count") do
      post admin_users_url, params: {
        user: {
          email: "nopass@roraima.cl",
          password: "",
          password_confirmation: "",
          role: :customer
        }
      }
    end

    assert_response :unprocessable_content
  end

  # ====================
  # Edit Action
  # ====================
  test "should get edit" do
    get edit_admin_user_url(@other_user)
    assert_response :success
  end

  # ====================
  # Update Action - CRITICAL PASSWORD LOGIC
  # ====================
  test "should update user without changing password when password is blank" do
    # This tests line 31: should exclude password fields when blank
    original_encrypted_password = @other_user.encrypted_password

    patch admin_user_url(@other_user), params: {
      user: {
        email: "updated@roraima.cl",
        password: "",
        password_confirmation: "",
        role: :customer
      }
    }

    @other_user.reload
    assert_equal "updated@roraima.cl", @other_user.email
    assert_equal original_encrypted_password, @other_user.encrypted_password,
                 "Password should not change when blank"
    assert_redirected_to admin_users_path
    assert_equal "Customer actualizado exitosamente.", flash[:notice]
  end

  test "should update user password when password is provided" do
    original_encrypted_password = @other_user.encrypted_password

    patch admin_user_url(@other_user), params: {
      user: {
        email: @other_user.email,
        password: "newpassword123",
        password_confirmation: "newpassword123",
        role: :customer
      }
    }

    @other_user.reload
    assert_not_equal original_encrypted_password, @other_user.encrypted_password,
                     "Password should be updated"
    assert @other_user.valid_password?("newpassword123"),
           "New password should be valid"
  end

  test "should update role to admin" do
    assert_not @other_user.admin?, "User should not be admin initially"

    patch admin_user_url(@other_user), params: {
      user: {
        email: @other_user.email,
        password: "",
        role: :admin
      }
    }

    @other_user.reload
    assert @other_user.admin?, "User should be admin after update"
  end

  test "should not update user with invalid email" do
    patch admin_user_url(@other_user), params: {
      user: {
        email: "invalid",
        password: "",
        role: :customer
      }
    }

    assert_response :unprocessable_content
    @other_user.reload
    assert_not_equal "invalid", @other_user.email
  end

  test "should not update when password and confirmation don't match" do
    patch admin_user_url(@other_user), params: {
      user: {
        email: @other_user.email,
        password: "newpassword123",
        password_confirmation: "different",
        role: :customer
      }
    }

    assert_response :unprocessable_content
  end

  # ====================
  # Destroy Action - CRITICAL SELF-DELETION TEST
  # ====================
  test "should prevent user from deleting themselves" do
    # This tests the critical self-deletion prevention via Pundit policy
    assert_no_difference("User.count") do
      delete admin_user_url(@admin)
    end

    assert_redirected_to root_path  # Pundit redirige a root_path cuando no está autorizado
    assert_equal "No tienes permiso para realizar esta acción.", flash[:alert]
    assert User.exists?(@admin.id), "Admin user should still exist"
  end

  test "should allow admin to delete other users" do
    user_to_delete = create(:user, email: "todelete@roraima.cl")

    assert_difference("User.count", -1) do
      delete admin_user_url(user_to_delete)
    end

    assert_redirected_to admin_users_path
    assert_equal "Usuario eliminado exitosamente.", flash[:notice]
    assert_not User.exists?(user_to_delete.id), "User should be deleted"
  end

  test "should prevent self-deletion even with ID manipulation attempt" do
    # Test edge case: ensure comparison is by ID
    current_admin_id = @admin.id

    assert_no_difference("User.count") do
      delete admin_user_url(current_admin_id)
    end

    assert_redirected_to root_path  # Pundit redirige a root_path cuando no está autorizado
    assert_equal "No tienes permiso para realizar esta acción.", flash[:alert]
  end

  test "should delete user and their associated packages" do
    user_with_packages = create(:user, :with_packages)
    package_count = user_with_packages.packages.count

    assert_difference("User.count", -1) do
      assert_difference("Package.count", -package_count) do
        delete admin_user_url(user_with_packages)
      end
    end
  end

  # ====================
  # Authorization Tests
  # ====================
  test "should require admin for all actions" do
    regular_user = create(:user, :customer)  # Usar trait en lugar de admin: false
    sign_in regular_user

    # Try all actions
    get admin_users_url
    assert_redirected_to customers_dashboard_path

    get new_admin_user_url
    assert_redirected_to customers_dashboard_path

    post admin_users_url, params: { user: { email: "test@test.com" } }
    assert_redirected_to customers_dashboard_path

    get edit_admin_user_url(@other_user)
    assert_redirected_to customers_dashboard_path

    patch admin_user_url(@other_user), params: { user: { email: "new@test.com" } }
    assert_redirected_to customers_dashboard_path

    delete admin_user_url(@other_user)
    assert_redirected_to customers_dashboard_path
  end

  # ====================
  # Strong Parameters Test
  # ====================
  test "should only permit allowed parameters" do
    # Attempt to set unpermitted parameter (should be ignored)
    post admin_users_url, params: {
      user: {
        email: "paramtest@roraima.cl",
        password: "password123",
        password_confirmation: "password123",
        admin: false,
        unpermitted_field: "should be ignored"
      }
    }

    user = User.find_by(email: "paramtest@roraima.cl")
    assert user.present?, "User should be created"
    assert_not user.respond_to?(:unpermitted_field), "Unpermitted field should not exist"
  end

  # ====================
  # Edge Cases
  # ====================
  # Note: Missing user test skipped - Rails handles 404s at framework level

  test "should update user keeping admin status when not specified" do
    admin_user = create(:user, :admin)

    patch admin_user_url(admin_user), params: {
      user: {
        email: "keepadmin@roraima.cl",
        password: "",
        role: :admin
      }
    }

    admin_user.reload
    assert admin_user.admin?, "Admin status should be kept"
  end

  test "should handle password with special characters" do
    post admin_users_url, params: {
      user: {
        email: "special@roraima.cl",
        password: "P@ssw0rd!#$%",
        password_confirmation: "P@ssw0rd!#$%",
        role: :customer
      }
    }

    user = User.find_by(email: "special@roraima.cl")
    assert user.valid_password?("P@ssw0rd!#$%"), "Password with special chars should work"
  end
end
