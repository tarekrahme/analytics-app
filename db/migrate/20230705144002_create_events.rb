class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.references :shopify_app, null: false, foreign_key: true
      t.datetime :occured_at
      t.string :event_type
      t.references :shop, null: false, foreign_key: true
      t.decimal :gross_amount, precision: 10, scale: 2
      t.date :billing_on

      t.timestamps
    end
  end
end
