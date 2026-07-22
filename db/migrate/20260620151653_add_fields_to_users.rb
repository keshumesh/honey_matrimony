class AddFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :hobbies, :text
    add_column :users, :highest_educational_details, :string
    add_column :users, :father_occupation, :string
    add_column :users, :family_details, :text
    add_column :users, :any_requirement, :text
    add_column :users, :food_type, :string, default: "Vegetarian"
  end
end
