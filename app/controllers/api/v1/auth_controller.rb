module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate_user!, only: [:register, :login]

      def register
        user = User.new(user_params)
        user.role = 'user'
        user.skip_matrimony_validation = true # Skip validations for now

        if user.save
          token = generate_token(user)
          render json: {
            message: 'User registered successfully',
            user: serialize_user(user),
            token: token
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = generate_token(user)
          render json: {
            message: 'Logged in successfully',
            user: serialize_user(user),
            token: token
          }, status: :ok
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end

      def logout
        # Token-based auth doesn't require logout on server side
        # Client should discard the token
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      def refresh_token
        # Simple token refresh - in production, use JWT with refresh tokens
        token = generate_token(current_user)
        render json: { token: token }, status: :ok
      end

      def current_user
        render json: serialize_user(current_user), status: :ok
      end

      private

      def user_params
        params.require(:user).permit(
          :first_name, :last_name, :email, :password, :password_confirmation,
          :mobile_no, :gender, :dob, :religion, :height, :marital_status,
          :complexion, :mother_tongue, :caste, :highest_educational_details, :food_type, :manglik
        )
      end

      def generate_token(user)
        # Simple token generation - in production, use JWT
        SecureRandom.urlsafe_base64(32)
      end

      def serialize_user(user)
        {
          id: user.id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          mobile_no: user.mobile_no,
          gender: user.gender,
          dob: user.dob,
          avatar: user.avatar&.url,
          role: user.role
        }
      end
    end
  end
end
