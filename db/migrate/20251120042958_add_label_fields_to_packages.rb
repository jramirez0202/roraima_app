class AddLabelFieldsToPackages < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:packages, :tracking_code)
      add_column :packages, :tracking_code, :string
    end

    unless column_exists?(:packages, :pickup_date)
      add_column :packages, :pickup_date, :date
    end

    unless index_exists?(:packages, :tracking_code, name: 'index_packages_on_tracking_code')
      add_index :packages, :tracking_code, unique: true
    end

    # Generar tracking_codes para paquetes existentes
    reversible do |dir|
      dir.up do
        if column_exists?(:packages, :tracking_code)
          Package.reset_column_information
          Package.where(tracking_code: nil).find_each do |package|
            package.update_column(:tracking_code, generate_unique_code)
          end
        end
      end
    end

    if column_exists?(:packages, :tracking_code)
      change_column_null :packages, :tracking_code, false
    end
  end

  private

  def generate_unique_code
    loop do
      random_digits = 14.times.map { rand(0..9) }.join
      code = "PKG-#{random_digits}"
      break code unless Package.exists?(tracking_code: code)
    end
  end
end
