class AddNotesToRoutes < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:routes, :notes)
      add_column :routes, :notes, :text
    end
  end
end
