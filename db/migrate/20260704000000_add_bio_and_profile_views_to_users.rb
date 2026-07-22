class AddBioAndProfileViewsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :bio, :text, default: ""
    add_column :users, :profile_views_count, :integer, default: 0

    # Add index for profile_views_count for sorting
    add_index :users, :profile_views_count
  end
end
