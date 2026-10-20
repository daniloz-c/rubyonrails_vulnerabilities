class CreateLabAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :lab_accounts do |t|
      t.string :name, null: false
      t.integer :balance, null: false, default: 100
      t.timestamps
    end
  end
end
