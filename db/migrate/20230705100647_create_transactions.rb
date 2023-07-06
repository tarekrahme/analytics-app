class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.references :shopify_app, null: false, foreign_key: true
      t.string :provider_id
      t.string :interval
      t.decimal :gross_amount, precision: 10, scale: 2
      t.decimal :net_amount, precision: 10, scale: 2
      t.decimal :shopify_fee, precision: 10, scale: 2
      t.datetime :provider_created_at
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end
  end
end
