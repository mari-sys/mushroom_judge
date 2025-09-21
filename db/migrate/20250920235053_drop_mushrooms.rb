class DropMushrooms < ActiveRecord::Migration[8.0]
  def change
    drop_table :mushrooms
  end
end
