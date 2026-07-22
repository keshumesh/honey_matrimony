class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :delete_gallery_photo, :browse_profile ]
  before_action :require_login, except: [ :new, :create, :index, :dashboard ]
  before_action :require_login, only: [ :dashboard, :browse, :skipped ]

  def index
    # Admin and Manager see all users
    # Regular users see only opposite gender users (not themselves), not admin/manager profiles
    if current_user&.admin? || current_user&.manager?
      @users = User.all.order(created_at: :desc)
    else
      opposite_gender = current_user&.gender == "Male" ? "Female" : "Male"
      @users = User.where(role: "user", gender: opposite_gender)
                    .where.not(id: current_user&.id)
                    .order(created_at: :desc)
    end

    # Apply search filters
    @users = apply_search_filters(@users)
  end

  def browse
    # Browse view for finding perfect matches

    # Get opposite gender profiles for current user
    if current_user.regular_user?
      opposite_gender = current_user.gender == "Male" ? "Female" : "Male"
      @users = User.where(role: "user", gender: opposite_gender)
                    .where.not(id: current_user.id)
                    .order(created_at: :desc)
    else
      # Admins and managers see all users
      @users = User.where.not(id: current_user.id).order(created_at: :desc)
    end

    # Exclude skipped profiles from browse view
    skipped_user_ids = current_user.sent_interactions.where(interaction_type: "rejected").pluck(:to_user_id)
    @users = @users.where.not(id: skipped_user_ids) unless skipped_user_ids.empty?

    # Apply search filters
    @users = apply_search_filters(@users)
  end

  def skipped
    # Show skipped profiles
    @skipped_interactions = current_user.sent_interactions
                                        .where(interaction_type: "rejected")
                                        .includes(:to_user)
                                        .order(created_at: :desc)
  end

  def dashboard
    @user = current_user

    # For regular users, fetch interaction data
    if @user.regular_user?
      # Suggested matches: opposite gender, not admin/manager, not self
      opposite_gender = @user.gender == "Male" ? "Female" : "Male"
      @suggested_matches = User.where(role: "user", gender: opposite_gender)
                                .where.not(id: @user.id)
                                .order(created_at: :desc)
                                .limit(10)

      # User interactions
      @sent_interests = @user.sent_interactions.where(interaction_type: "interested").count
      @received_interests = @user.received_interactions.where(interaction_type: "interested").count
      @shortlisted = @user.sent_interactions.where(interaction_type: "shortlist").count

      # Activity data
      @recent_interactions = @user.received_interactions.order(created_at: :desc).limit(5)
      @shortlist_profiles = @user.sent_interactions.where(interaction_type: "shortlist").includes(:to_user).limit(6)

      # New Dashboard Data

      # Profile Strength Calculation
      @profile_strength = calculate_profile_strength(@user)
      @strength_tips = get_strength_tips(@user)

      # Quick Stats
      @profile_views = @user.profile_views_count || 0 # Track how many times profile was viewed today
      @new_connection_requests = @user.received_interactions.where(interaction_type: "interested", created_at: Date.today.all_day).count

      # Daily AI Picks (Top matched profiles refreshed daily)
      @daily_picks = generate_daily_picks(@user, 6)

      # Recent Conversations (from sent/received interactions)
      @recent_conversations = build_recent_conversations(@user)

      # Notifications and Messages
      @unread_messages = @user.received_interactions.count
      @notifications = @user.received_interactions.where(interaction_type: "interested").count
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.skip_matrimony_validation = true

    if @user.save
      session[:user_id] = @user.id
      redirect_to edit_user_path(@user), notice: "Quick profile created! Now complete your profile details."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Show own profile - no restrictions
    # This is for viewing your own profile from dashboard/menu
  end

  def browse_profile
    # Prevent regular users from viewing admin/manager profiles or same-gender profiles
    if current_user.regular_user? && (@user.admin? || @user.manager?)
      flash[:alert] = "You don't have permission to view this profile"
      redirect_to users_path
    elsif current_user.regular_user? && @user.regular_user? && current_user.gender == @user.gender
      flash[:alert] = "You can only view profiles of opposite gender"
      redirect_to users_path
    end

    # Track profile view if logged in and viewing someone else's profile
    if logged_in? && current_user.id != @user.id
      @user.increment!(:profile_views_count)
    end

    # Render browse profile view with interaction buttons
    render :browse_profile
  end

  def edit
  end

  def update
    if @user.update(user_params)
      handle_gallery_uploads if params[:user][:gallery_photo_files].present?
      @user.save
      redirect_to @user, notice: "Profile updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def delete_gallery_photo
    photo_path = params[:photo]

    # Delete the file from storage
    full_path = "public#{photo_path}"
    File.delete(full_path) if File.exist?(full_path)

    # Remove from gallery_photos array
    @user.remove_gallery_photo(photo_path)
    @user.save

    redirect_to edit_user_path(@user), notice: "Photo deleted successfully!"
  end

  def destroy
    @user.destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Account deleted successfully!"
  end

  def import_pdf
    # Only admin can import users via PDF
    unless current_user&.admin?
      flash[:alert] = "You do not have permission to import users"
      redirect_to root_path and return
    end
  end

  def import_image
    # Only admin and manager can import users via image
    unless current_user&.admin? || current_user&.manager?
      flash[:alert] = "You do not have permission to import users"
      redirect_to root_path and return
    end
  end

  def process_pdf
    # Only admin can import users via PDF
    unless current_user&.admin?
      flash[:alert] = "You do not have permission to import users"
      redirect_to root_path and return
    end

    if params[:pdf_file].blank?
      flash[:alert] = "Please select a PDF file"
      redirect_to import_pdf_users_path and return
    end

    # Save the uploaded file temporarily
    pdf_file = params[:pdf_file]
    temp_path = "#{Rails.root}/tmp/#{pdf_file.original_filename}"

    begin
      # Write the file
      File.open(temp_path, "wb") do |f|
        f.write(pdf_file.read)
      end

      # Process the PDF
      importer = PdfImportService.new(temp_path)
      if importer.import
        # Build success message with extracted data
        if importer.extracted_data.any?
          flash[:notice] = "Successfully imported #{importer.created_users.length} matrimony profile(s)!"

          # Show details of extracted data
          if importer.created_users.any?
            details = importer.created_users.map { |u| "#{u.first_name} #{u.last_name} (#{u.email})" }.join(", ")
            flash[:notice] += " Imported: #{details}"
          end
        else
          flash[:notice] = "Successfully created #{importer.created_users.length} user(s) from PDF"
        end

        importer.errors.each { |error| flash[:alert] = error } if importer.errors.any?
        redirect_to users_path
      else
        importer.errors.each { |error| flash[:alert] = error }
        redirect_to import_pdf_users_path
      end
    ensure
      # Clean up temporary file
      File.delete(temp_path) if File.exist?(temp_path)
    end
  end

  def process_image
    # Admin and Manager can import users via image
    unless current_user&.admin? || current_user&.manager?
      flash[:alert] = "You do not have permission to import users"
      redirect_to root_path and return
    end

    if params[:image_file].blank? && params[:extracted_text].blank?
      flash[:alert] = "Please select an image file or paste extracted text"
      redirect_to import_image_users_path and return
    end

    importer = nil
    temp_path = nil

    begin
      if params[:image_file].present?
        # Process image file with OCR
        image_file = params[:image_file]
        temp_path = "#{Rails.root}/tmp/#{Time.now.to_i}_#{image_file.original_filename}"

        File.open(temp_path, "wb") do |f|
          f.write(image_file.read)
        end

        importer = ImageImportService.new(temp_path)
      elsif params[:extracted_text].present?
        # Process pasted text (fallback when OCR not available)
        importer = ImageImportService.new(params[:extracted_text])
      end

      if importer && importer.import
        if importer.created_users.any?
          flash[:notice] = "Successfully imported #{importer.created_users.length} user(s)!"
          details = importer.created_users.map { |u| "#{u.first_name} #{u.last_name} (#{u.email})" }.join(", ")
          flash[:notice] += " Imported: #{details}"
        end

        importer.errors.each { |error| flash[:alert] = error } if importer.errors.any?
        redirect_to users_path
      else
        importer&.errors&.each { |error| flash[:alert] = error }
        flash[:alert] ||= "Failed to import users"
        redirect_to import_image_users_path
      end
    rescue StandardError => e
      Rails.logger.error "Image import error: #{e.message}"
      flash[:alert] = "Error processing: #{e.message}"
      redirect_to import_image_users_path
    ensure
      File.delete(temp_path) if temp_path && File.exist?(temp_path)
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def calculate_profile_strength(user)
    strength = 0

    # 20% - Basic Info
    strength += 20 if user.first_name.present? && user.last_name.present?

    # 15% - Avatar
    strength += 15 if user.avatar.present?

    # 15% - Gender
    strength += 15 if user.gender.present?

    # 10% - Date of Birth
    strength += 10 if user.dob.present?

    # 10% - Religion
    strength += 10 if user.religion.present?

    # 10% - Caste
    strength += 10 if user.caste.present?

    # 10% - Bio/About Section
    strength += 10 if user.bio.present? && user.bio.length > 50

    [ strength, 100 ].min
  end

  def get_strength_tips(user)
    tips = []

    tips << "Add a video prompt to hit 100%!" unless user.video_present?
    tips << "Complete your bio with more details" unless user.bio.present? && user.bio.length > 50
    tips << "Add more photos to your gallery" unless user.gallery_photos.count > 2
    tips << "Update your caste information" unless user.caste.present?
    tips << "Add your religion details" unless user.religion.present?

    tips
  end

  def generate_daily_picks(user, limit = 6)
    opposite_gender = user.gender == "Male" ? "Female" : "Male"

    # Get profiles not yet interacted with
    User.where(role: "user", gender: opposite_gender)
        .where.not(id: user.id)
        .order("RANDOM()")
        .limit(limit)
  end

  def build_recent_conversations(user)
    conversations = []

    # Get recent interactions (both sent and received)
    interactions = (
      user.sent_interactions.order(created_at: :desc) +
      user.received_interactions.order(created_at: :desc)
    ).uniq { |i| i.from_user_id == user.id ? i.to_user_id : i.from_user_id }
     .sort_by { |i| i.created_at }
     .reverse
     .take(5)

    interactions.each do |interaction|
      other_user = interaction.from_user_id == user.id ? interaction.to_user : interaction.from_user

      conversations << {
        name: "#{other_user.first_name} #{other_user.last_name}",
        avatar: other_user.avatar.present? ? other_user.avatar.url(:thumb) : nil,
        status: determine_user_status(other_user),
        message: interaction.notes.present? ? interaction.notes : "Started a conversation"
      }
    end

    conversations
  end

  def determine_user_status(user)
    # This is a placeholder - you can implement actual last_seen tracking
    if user.updated_at > 1.hour.ago
      "🟢 Online"
    elsif user.updated_at > 1.day.ago
      "Last active today"
    else
      "Last active #{time_ago_in_words(user.updated_at)} ago"
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :middle_name, :last_name,
                                  :profile_for, :gender, :dob, :time_of_birth, :rashi, :nakshtra, :height,
                                  :marital_status, :religion, :mother_tongue, :caste, :sub_caste, :gotra, :ban,
                                  :manglik, :complexion, :heighst_education, :job, :organization_name, :annual_income,
                                  :f_first_name, :f_middle_name, :f_last_name, :m_first_name, :m_middle_name, :m_last_name,
                                  :sisters, :brothers, :mobile_no, :address, :role, :avatar, :additional_photos,
                                  :blood_group, :extra_phone_number, :maternal_surname, :hobbies, :highest_educational_details,
                                  :father_occupation, :family_details, :any_requirement, :food_type, :manglik_status, :bio)
  end

  def handle_gallery_uploads
    files = params[:user][:gallery_photo_files]
    return unless files.present?

    current_count = @user.gallery_photos.length

    files.each do |file|
      break if current_count >= 5

      if file.present?
        # Create a unique filename with timestamp
        unique_filename = "#{Time.now.to_i}_#{SecureRandom.hex(4)}_#{file.original_filename}"
        upload_path = "public/uploads/user/gallery/#{@user.id}"
        FileUtils.mkdir_p(upload_path) unless Dir.exist?(upload_path)

        # Save the file
        File.open("#{upload_path}/#{unique_filename}", "wb") do |f|
          f.write(file.read)
        end

        @user.add_gallery_photo("/uploads/user/gallery/#{@user.id}/#{unique_filename}")
        current_count += 1
      end
    end
  end

  def apply_search_filters(users)
    # Debug: Log incoming params
    Rails.logger.info "=== FILTER PARAMS: #{params.inspect}"

    # Filter by name (first_name or last_name)
    if params[:search_name].present?
      search_term = "%#{params[:search_name]}%"
      users = users.where("first_name ILIKE ? OR last_name ILIKE ?", search_term, search_term)
    end

    # Filter by gender (for admin and manager)
    if params[:search_gender].present?
      users = users.where(gender: params[:search_gender])
    end

    # Filter by age (min_age and/or max_age)
    if params[:min_age].present? && params[:min_age].to_i > 0
      min_age = params[:min_age].to_i
      users = users.where("dob <= ?", Date.today - min_age.years)
    end

    if params[:max_age].present? && params[:max_age].to_i > 0
      max_age = params[:max_age].to_i
      users = users.where("dob >= ?", Date.today - max_age.years)
    end

    # Filter by address/location
    if params[:search_address].present?
      search_term = "%#{params[:search_address]}%"
      users = users.where("address ILIKE ?", search_term)
    end

    if params[:location].present?
      search_term = "%#{params[:location]}%"
      users = users.where("address ILIKE ?", search_term)
    end

    # Filter by religion - accept both "1" and "on" values
    religions = []
    religions << "Hindu" if [ "1", "on" ].include?(params[:religion_hindu])
    religions << "Muslim" if [ "1", "on" ].include?(params[:religion_muslim])
    religions << "Sikh" if [ "1", "on" ].include?(params[:religion_sikh])
    religions << "Christian" if [ "1", "on" ].include?(params[:religion_christian])

    if religions.any?
      Rails.logger.info "=== FILTERING BY RELIGIONS: #{religions.inspect}"
      users = users.where(religion: religions)
    end

    # Filter by profession - accept both "1" and "on" values
    professions = []
    professions << "IT/Tech" if [ "1", "on" ].include?(params[:profession_it])
    professions << "Medical" if [ "1", "on" ].include?(params[:profession_medical])
    professions << "Business" if [ "1", "on" ].include?(params[:profession_business])
    professions << "Other" if [ "1", "on" ].include?(params[:profession_other])

    if professions.any?
      Rails.logger.info "=== FILTERING BY PROFESSIONS: #{professions.inspect}"
      users = users.where(job: professions)
    end

    Rails.logger.info "=== FINAL RESULTS COUNT: #{users.count}"
    users
  end
end
