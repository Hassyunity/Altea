class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :account, null: false, foreign_key: true
      # destination account, for transfers between two of my own accounts
      t.references :transfer_account, foreign_key: { to_table: :accounts }
      t.string :kind, null: false, default: "expense"
      t.bigint :amount_cents, null: false
      t.date :occurred_on, null: false
      t.string :category
      t.string :description

      t.timestamps
    end

    add_index :transactions, :occurred_on
    add_index :transactions, [ :account_id, :occurred_on ]
    add_index :transactions, [ :kind, :category ]
  end
end
