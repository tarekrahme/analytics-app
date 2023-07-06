class AddUniqueIndexOnPlans < ActiveRecord::Migration[7.0]
  def change
    add_index :plans, [:shopify_app_id, :amount], unique: true
  end
end
