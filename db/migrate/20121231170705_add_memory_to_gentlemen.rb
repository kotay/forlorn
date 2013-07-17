class AddMemoryToGentlemen < ActiveRecord::Migration
  def change
    add_column :gentlemen, :memory, :text
  end
end
