class PhotoUploader < CarrierWave::Uploader::Base
  # Include MiniMagick support for image processing
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  def store_dir
    user_id = model.respond_to?(:id) ? model.id : "temp"
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{user_id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url(*args)
    ActionController::Base.helpers.asset_path("fallback/photo_default.png")
  end

  # Process files as they are uploaded:
  process resize_to_fit: [ 600, 600 ]

  # Create different versions of your uploaded files:
  version :thumb do
    process resize_to_fit: [ 150, 150 ]
  end

  version :medium do
    process resize_to_fit: [ 400, 400 ]
  end

  # Add an allowlist of extensions which are allowed to be uploaded.
  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  # Override the filename of the uploaded files:
  def filename
    "photo_#{Time.now.to_i}.#{file.extension}" if original_filename
  end
end
