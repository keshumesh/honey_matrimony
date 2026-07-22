CarrierWave.configure do |config|
  # Use file storage (instead of cloud storage)
  config.storage = :file

  # Set upload directory
  config.asset_host = "http://localhost:3000"
  config.permissions = 0o666
  config.directory_permissions = 0o777

  # Silence polymorphic column type warning (only if you're not using polymorphic associations)
  config.ignore_integrity_errors = true
end
