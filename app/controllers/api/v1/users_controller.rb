module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy, :browse_profile, :delete_gallery_photo, :upload_gallery_photo]

      def index
        # Get list of profiles to browse (excluding current user and those already interacted with)
        @users = User.where(role: 'user')
                     .where.not(id: current_user.id)
                     .where.not(gender: current_user.gender)
                     .limit(50)
        render json: @users.map { |u| serialize_user(u) }, status: :ok
      end

      def show
        render json: serialize_user_full(@user), status: :ok
      end

      def update
        @user = current_user
        if @user.update(user_update_params)
          render json: {
            message: 'Profile updated successfully',
            user: serialize_user_full(@user)
          }, status: :ok
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @user = current_user
        @user.destroy
        render json: { message: 'User deleted successfully' }, status: :ok
      end

      def browse_profile
        render json: serialize_user_full(@user), status: :ok
      end

      def search
        query = params[:q]
        @users = User.where(role: 'user')
                     .where.not(gender: current_user.gender)
                     .where.not(id: current_user.id)
                     .where("first_name ILIKE ? OR last_name ILIKE ? OR city ILIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
        render json: @users.map { |u| serialize_user(u) }, status: :ok
      end

      def suggestions
        # Get suggestions based on preferences
        @users = User.where(role: 'user')
                     .where.not(gender: current_user.gender)
                     .where.not(id: current_user.id)
                     .limit(20)
                     .order(created_at: :desc)
        render json: @users.map { |u| serialize_user(u) }, status: :ok
      end

      def delete_gallery_photo
        photo_index = params[:index].to_i
        @user = current_user
        photos = @user.gallery_photos || []
        if photos.delete_at(photo_index)
          @user.gallery_photos = photos
          @user.save
          render json: { message: 'Photo deleted successfully' }, status: :ok
        else
          render json: { error: 'Photo not found' }, status: :not_found
        end
      end

      def upload_gallery_photo
        @user = current_user
        uploaded_file = params[:photo]
        if uploaded_file
          uploader = PhotoUploader.new
          filename = uploader.store!(uploaded_file)
          @user.gallery_photos ||= []
          @user.gallery_photos << filename.to_s
          @user.save
          render json: {
            message: 'Photo uploaded successfully',
            photo_url: uploader.url
          }, status: :created
        else
          render json: { error: 'No photo provided' }, status: :bad_request
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_update_params
        params.require(:user).permit(
          :first_name, :last_name, :mobile_no, :dob, :gender, :religion, :height,
          :marital_status, :complexion, :mother_tongue, :caste, :highest_educational_details,
          :job, :organization_name, :annual_income, :food_type, :manglik,
          :hobbies, :family_details, :any_requirement, :blood_group, :avatar
        )
      end

      def serialize_user(user)
        {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          gender: user.gender,
          age: calculate_age(user.dob),
          height: user.height,
          religion: user.religion,
          caste: user.caste,
          avatar: user.avatar&.url,
          city: user.address
        }
      end

      def serialize_user_full(user)
        {
          id: user.id,
          first_name: user.first_name,
          middle_name: user.middle_name,
          last_name: user.last_name,
          email: user.email,
          mobile_no: user.mobile_no,
          gender: user.gender,
          dob: user.dob,
          age: calculate_age(user.dob),
          height: user.height,
          religion: user.religion,
          caste: user.caste,
          sub_caste: user.sub_caste,
          marital_status: user.marital_status,
          complexion: user.complexion,
          mother_tongue: user.mother_tongue,
          job: user.job,
          organization_name: user.organization_name,
          annual_income: user.annual_income,
          food_type: user.food_type,
          manglik: user.manglik,
          blood_group: user.blood_group,
          hobbies: user.hobbies,
          family_details: user.family_details,
          any_requirement: user.any_requirement,
          avatar: user.avatar&.url,
          gallery_photos: user.gallery_photos || [],
          created_at: user.created_at
        }
      end

      def calculate_age(dob)
        return nil unless dob
        ((Time.zone.now - dob.to_time) / 1.year.seconds).floor
      end
    end
  end
end
