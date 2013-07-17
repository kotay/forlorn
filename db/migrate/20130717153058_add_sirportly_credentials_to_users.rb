class AddSirportlyCredentialsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :token, :string
    add_column :users, :key, :string
    add_column :users, :secret, :string
    add_column :users, :domain, :string, :default => "https://api.sirportly.com"
  end
end
