class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.string :title, null: false
      t.text :body
      t.string :life_area, null: false
      t.boolean :pinned, null: false, default: false
      t.references :project, foreign_key: true

      t.timestamps
    end

    add_index :notes, [ :life_area, :pinned ]
  end
end
