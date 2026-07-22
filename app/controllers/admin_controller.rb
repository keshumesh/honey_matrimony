class AdminController < ApplicationController
  before_action :require_manager_or_admin
  before_action :set_user, only: [ :show, :edit, :update, :delete, :destroy, :delete_gallery_photo ]

  def dashboard
    @total_users = User.count
    @total_admins = User.where(role: "admin").count
    @total_managers = User.where(role: "manager").count
    @total_users_count = User.where(role: "user").count
    @recent_users = User.order(created_at: :desc).limit(10)
  end

  def users
    # Admins see all users, Managers see only regular users
    if current_user.admin?
      @users = User.all.order(created_at: :desc)
    else
      # Manager can only see regular users
      @users = User.where(role: "user").order(created_at: :desc)
    end
    @users = @users.where("first_name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(admin_user_params)
    @user.skip_matrimony_validation = true

    if @user.save
      redirect_to admin_users_path, notice: "User created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Prevent managers from viewing admin users
    if current_user.manager? && @user.admin?
      flash[:alert] = "You don't have permission to view this user"
      redirect_to admin_users_path
    end
  end

  def edit
    # Prevent managers from editing admin users
    if current_user.manager? && @user.admin?
      flash[:alert] = "You don't have permission to edit this user"
      redirect_to admin_users_path
    end
  end

  def update
    # Prevent managers from updating admin users
    if current_user.manager? && @user.admin?
      flash[:alert] = "You don't have permission to update this user"
      redirect_to admin_users_path
      return
    end

    @user.skip_matrimony_validation = true
    if @user.update(admin_user_params)
      handle_gallery_uploads if params[:user][:gallery_photo_files].present?
      @user.save
      redirect_to admin_user_path(@user), notice: "User updated successfully!"
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

    redirect_to edit_admin_user_path(@user), notice: "Photo deleted successfully!"
  end

  def delete
    # Prevent managers from deleting admin users
    if current_user.manager? && @user.admin?
      flash[:alert] = "You don't have permission to delete this user"
      redirect_to admin_users_path
    end
  end

  def destroy
    # Prevent managers from destroying admin users
    if current_user.manager? && @user.admin?
      flash[:alert] = "You don't have permission to delete this user"
      redirect_to admin_users_path
      return
    end

    @user.destroy
    redirect_to admin_users_path, notice: "User deleted successfully!"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def admin_user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :middle_name, :last_name,
                                  :profile_for, :gender, :dob, :time_of_birth, :rashi, :nakshtra, :height,
                                  :marital_status, :religion, :mother_tongue, :caste, :sub_caste, :gotra, :ban,
                                  :manglik, :complexion, :heighst_education, :job, :organization_name, :annual_income,
                                  :f_first_name, :f_middle_name, :f_last_name, :m_first_name, :m_middle_name, :m_last_name,
                                  :sisters, :brothers, :mobile_no, :address, :role, :avatar, :additional_photos,
                                  :blood_group, :extra_phone_number, :maternal_surname, :hobbies, :highest_educational_details,
                                  :father_occupation, :family_details, :any_requirement, :food_type, :manglik)
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
end
