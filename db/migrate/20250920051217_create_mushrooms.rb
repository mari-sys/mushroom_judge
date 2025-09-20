class CreateMushrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :mushrooms do |t|
      t.string :name
      t.boolean :is_poisonous
      t.string :image_url
      t.text :description

      t.timestamps
    end
  end
end
