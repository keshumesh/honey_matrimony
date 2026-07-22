class AddLifestyleFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :smoking_frequency, :string, default: "Never"
    add_column :users, :alcohol_frequency, :string, default: "Never"
  end
end
