class User < ApplicationRecord
  has_secure_password

  # CarrierWave uploaders
  mount_uploader :avatar, AvatarUploader
  mount_uploader :additional_photos, PhotoUploader

  # Serialize gallery_photos as JSON array
  serialize :gallery_photos, coder: JSON, type: Array

  # Relationships for interactions
  has_many :sent_interactions, class_name: "UserInteraction", foreign_key: "from_user_id", dependent: :destroy
  has_many :received_interactions, class_name: "UserInteraction", foreign_key: "to_user_id", dependent: :destroy

  # Attribute for skipping matrimony validation during admin updates
  attr_accessor :skip_matrimony_validation, :gallery_photo_files

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: -> { oauth_login? }
  validates :password, presence: true, length: { minimum: 6 }, if: -> { email_login? && (new_record? || !password.nil?) }
  validates :first_name, :gender, :mobile_no, :role, presence: true
  validates :mobile_no, format: { with: /\A\d{10}\z/, message: "must be 10 digits" }, uniqueness: true, allow_nil: true
  validates :role, inclusion: { in: %w[user manager admin], message: "%{value} is not a valid role" }
  validates :provider, :uid, presence: true, if: :oauth_login?
  validate :gallery_photos_count

  # Conditional validations - only required for regular users
  validates :last_name, :dob, :religion, :height, :marital_status, :complexion, :mother_tongue,
            :caste, :manglik,
            presence: true, unless: :matrimony_details_not_required?

  # Role enums
  enum role: { user: "user", manager: "manager", admin: "admin" }

  # Role-based methods
  def admin?
    role == "admin"
  end

  def matrimony_details_not_required?
    admin? || manager? || skip_matrimony_validation
  end

  def admin_or_skip_matrimony?
    admin? || skip_matrimony_validation
  end

  def manager?
    role == "manager"
  end

  def regular_user?
    role == "user"
  end

  def can_manage_users?
    admin? || manager?
  end

  def can_edit_user?(other_user)
    admin? || (manager? && other_user.regular_user?) || self == other_user
  end

  def can_delete_user?(other_user)
    admin? || (self == other_user)
  end

  # OAuth and login type helper methods
  def oauth_login?
    provider.present? && uid.present?
  end

  def email_login?
    provider.blank?
  end

  def google_login?
    provider == "google_oauth2"
  end

  def facebook_login?
    provider == "facebook"
  end

  # Find or create user from OAuth data
  def self.from_omniauth(auth_hash)
    provider = auth_hash["provider"]
    uid = auth_hash["uid"]
    email = auth_hash["info"]["email"]
    name = auth_hash["info"]["name"]

    user = find_by(provider: provider, uid: uid)
    return user if user.present?

    # Create new user from OAuth
    user = new
    user.provider = provider
    user.uid = uid
    user.email = email
    user.first_name = name&.split&.first || "User"
    user.last_name = name&.split&.last || uid
    user.role = "user"
    user.gender = "Not Specified" # Will need to be set during profile completion
    user.mobile_no = "0000000000" # Placeholder - will need to be set during profile completion

    # Store OAuth tokens
    if provider == "google_oauth2"
      user.google_access_token = auth_hash["credentials"]["access_token"]
    elsif provider == "facebook"
      user.facebook_access_token = auth_hash["credentials"]["access_token"]
    end

    user.save(validate: false) # Skip validations as matrimony details not available yet
    user
  end

  # Find user by mobile number and authenticate with password
  def self.find_by_mobile_and_authenticate(mobile_no, password)
    user = find_by(mobile_no: mobile_no)
    return nil unless user
    return nil unless user.authenticate(password)
    user
  end

  # Token-based authentication for API
  def self.find_by_token(token)
    # For now, this is a simple lookup. In production, use JWT.
    # This would require a token column in the users table
    nil
  end

  # Gallery photo management methods
  def gallery_photos
    (read_attribute(:gallery_photos) || []).compact
  end

  def add_gallery_photo(filename)
    current_photos = gallery_photos
    current_photos << filename if current_photos.length < 5
    write_attribute(:gallery_photos, current_photos)
  end

  def remove_gallery_photo(filename)
    current_photos = gallery_photos
    current_photos.delete(filename)
    write_attribute(:gallery_photos, current_photos)
  end

  def gallery_photos_count_left
    5 - gallery_photos.length
  end

  def video_present?
    # Placeholder for video presence check
    # Add video column to users table if implementing actual video support
    false
  end

  def last_seen_recently?
    updated_at > 30.minutes.ago
  end

  def match_score
    # Placeholder for match score calculation
    # Will be calculated based on preferences matching
    rand(80..95)
  end

  private

  def gallery_photos_count
    if gallery_photos.length > 5
      errors.add(:gallery_photos, "cannot exceed 5 images")
    end
  end
end
