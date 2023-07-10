class AddUniqueIndexToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_index :transactions, :provider_id, unique: true
    add_index :transactions, [:shop_id, :provider_id], unique: true, name: 'index_transactions_on_shop_id_and_provider_id'
  end
end
