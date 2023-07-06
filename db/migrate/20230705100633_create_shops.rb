class CreateShops < ActiveRecord::Migration[7.0]
  def change
    create_table :shops do |t|
      t.references :shopify_app, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :shopify_domain
      t.string :provider_id
      t.string :name

      t.timestamps
    end
  end
end
