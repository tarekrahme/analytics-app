class CreateApps < ActiveRecord::Migration[7.0]
  def change
    create_table :shopify_apps do |t|
      t.string :name
      t.string :provider_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
