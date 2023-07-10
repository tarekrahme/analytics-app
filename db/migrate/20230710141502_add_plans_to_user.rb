class AddPlansToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :plan, :integer
  end
end
