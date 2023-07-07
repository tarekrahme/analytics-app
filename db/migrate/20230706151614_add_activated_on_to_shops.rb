class AddActivatedOnToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :activated_on, :datetime
  end
end
