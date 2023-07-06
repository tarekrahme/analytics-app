class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.decimal :amount, precision: 10, scale: 2
      t.references :shopify_app, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
