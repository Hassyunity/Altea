class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :kind, null: false, default: "bank"
      t.string :institution
      t.string :currency, null: false, default: "MGA"
      t.bigint :opening_balance_cents, null: false, default: 0
      t.string :color
      t.text :notes
      t.boolean :archived, null: false, default: false
      t.string :life_area, null: false, default: "personal"

      t.timestamps
    end

    add_index :accounts, [ :life_area, :archived ]
  end
end
