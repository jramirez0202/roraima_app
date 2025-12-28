class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.boolean :require_driver_authorization, default: false, null: false

      t.timestamps
    end

    # Create the single settings record
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO settings (require_driver_authorization, created_at, updated_at)
          VALUES (false, NOW(), NOW())
        SQL
      end
    end
  end
end
