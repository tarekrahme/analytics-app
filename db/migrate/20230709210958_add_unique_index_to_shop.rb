class AddUniqueIndexToShop < ActiveRecord::Migration[7.0]
  def change
    add_index :shops, [:user_id, :provider_id], unique: true
  end
end
