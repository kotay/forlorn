class CreateGentlemen < ActiveRecord::Migration
  def change
    create_table :gentlemen do |t|
      t.integer :user_id
      t.text :options
      t.string :type
      t.string :name
      t.string :schedule
      t.integer :events_count
      t.datetime :last_check_at
      t.datetime :last_receive_at
      t.integer :last_checked_event_id
      t.timestamps
    end

    add_index :gentlemen, [:user_id, :created_at]
    add_index :gentlemen, :type
    add_index :gentlemen, :schedule
  end
end
