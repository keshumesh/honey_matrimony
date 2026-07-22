class AddOauthColumnsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :google_access_token, :string
    add_column :users, :facebook_access_token, :string
    add_column :users, :login_type, :string, default: "email" # email, mobile, google, facebook

    # Add index for provider and uid for faster lookups
    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :mobile_no
  end
end
