class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.string :life_area, null: false
      t.string :status, null: false, default: "active"
      t.string :color

      t.timestamps
    end

    add_index :projects, [ :life_area, :status ]
  end
end
