class CreateColors < ActiveRecord::Migration[7.0]
  def change
    create_table :colors do |t|
      t.string :label, null: false
      t.string :css_class, null: false
      t.integer :position

      t.timestamps
    end
  end
end
