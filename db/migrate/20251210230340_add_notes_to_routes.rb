class AddNotesToRoutes < ActiveRecord::Migration[7.1]
  def change
    add_column :routes, :notes, :text
  end
end
