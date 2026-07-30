class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :details
      t.string :life_area, null: false
      t.string :status, null: false, default: "todo"
      t.string :priority, null: false, default: "normal"
      t.date :due_on
      t.datetime :completed_at
      t.references :project, foreign_key: true

      t.timestamps
    end

    add_index :tasks, [ :life_area, :status ]
    add_index :tasks, :due_on
  end
end
