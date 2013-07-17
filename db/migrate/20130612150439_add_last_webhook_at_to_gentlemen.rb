class AddLastWebhookAtToGentlemen < ActiveRecord::Migration
  def change
    add_column :gentlemen, :last_webhook_at, :datetime
  end
end
