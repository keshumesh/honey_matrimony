class AddAvatarAndPhotosToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :avatar, :string
    add_column :users, :additional_photos, :string
    add_column :users, :blood_group, :string
    add_column :users, :extra_phone_number, :string
    add_column :users, :maternal_surname, :string
  end
end
