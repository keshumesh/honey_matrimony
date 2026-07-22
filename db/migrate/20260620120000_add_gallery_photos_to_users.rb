class AddGalleryPhotosToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :gallery_photos, :text, default: "[]", comment: "JSON array storing up to 5 photo filenames"
  end
end
