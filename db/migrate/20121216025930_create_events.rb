class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :user_id
      t.integer :gentleman_id
      t.decimal :lat, :precision => 15, :scale => 10
      t.decimal :lng, :precision => 15, :scale => 10
      t.text :payload
      t.timestamps
    end

    add_index :events, [:user_id, :created_at]
    add_index :events, [:gentleman_id, :created_at]
  end
end
