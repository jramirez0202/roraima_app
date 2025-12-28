class AddLabelFieldsToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :tracking_code, :string
    add_column :packages, :pickup_date, :date

    add_index :packages, :tracking_code, unique: true

    # Generar tracking_codes para paquetes existentes
    reversible do |dir|
      dir.up do
        Package.reset_column_information
        Package.find_each do |package|
          package.update_column(:tracking_code, generate_unique_code)
        end
      end
    end

    change_column_null :packages, :tracking_code, false
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
