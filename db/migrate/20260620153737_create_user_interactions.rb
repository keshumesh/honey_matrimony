class CreateUserInteractions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_interactions do |t|
      t.references :from_user, null: false, foreign_key: { to_table: :users }
      t.references :to_user, null: false, foreign_key: { to_table: :users }
      t.string :interaction_type, null: false, default: "interested"
      t.text :notes
      t.string :status, default: "pending"

      t.timestamps
    end

    add_index :user_interactions, [ :from_user_id, :to_user_id ], unique: true
  end
end
