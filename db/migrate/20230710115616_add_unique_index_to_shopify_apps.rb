class AddUniqueIndexToShopifyApps < ActiveRecord::Migration[7.0]
  def change
    add_index :shopify_apps, :provider_id, unique: true
    add_index :shopify_apps, [:user_id, :provider_id], unique: true
  end
end
