class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    unless table_exists?(:settings)
      create_table :settings do |t|
        t.boolean :require_driver_authorization, default: false, null: false

        t.timestamps
      end
    end

    # Create the single settings record
    reversible do |dir|
      dir.up do
        if table_exists?(:settings) && Setting.count == 0
          execute <<-SQL
            INSERT INTO settings (require_driver_authorization, created_at, updated_at)
            VALUES (false, NOW(), NOW())
          SQL
        end
      end
    end
  end
end
