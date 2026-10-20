class CreateLabUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :lab_users do |t|
      t.string :username, null: false
      t.string :role, null: false, default: "user"
      t.timestamps
    end
    add_index :lab_users, :username, unique: true
  end
end
