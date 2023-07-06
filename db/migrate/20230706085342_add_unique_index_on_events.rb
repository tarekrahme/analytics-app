class AddUniqueIndexOnEvents < ActiveRecord::Migration[7.0]
  def change
    add_index :events, [:shopify_app_id, :shop_id, :event_type, :occured_at], unique: true, name: "index_events_on_app_and_shop_and_event_type_and_occured_at"
  end
end
