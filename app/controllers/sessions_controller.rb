class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :google_callback, :facebook_callback ]

  def new
  end

  def create
    # Determine login type and authenticate accordingly
    login_type = params[:login_type] || "email"

    case login_type
    when "mobile"
      handle_mobile_login
    when "email"
      handle_email_login
    else
      flash.now[:alert] = "Invalid login method"
      render :new
    end
  end

  def google_callback
    auth_hash = request.env["omniauth.auth"]
    user = User.from_omniauth(auth_hash)

    if user.persisted?
      session[:user_id] = user.id

      # Check if user has completed profile
      if user.gender == "Not Specified" || user.dob.nil?
        redirect_to edit_user_path(user), notice: "Please complete your profile to continue"
      else
        redirect_to user_path(user), notice: "Logged in successfully!"
      end
    else
      flash[:alert] = "Failed to authenticate with Google"
      redirect_to root_path
    end
  end

  def facebook_callback
    auth_hash = request.env["omniauth.auth"]
    user = User.from_omniauth(auth_hash)

    if user.persisted?
      session[:user_id] = user.id

      # Check if user has completed profile
      if user.gender == "Not Specified" || user.dob.nil?
        redirect_to edit_user_path(user), notice: "Please complete your profile to continue"
      else
        redirect_to user_path(user), notice: "Logged in successfully!"
      end
    else
      flash[:alert] = "Failed to authenticate with Facebook"
      redirect_to root_path
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out successfully!"
  end

  def auth_failure
    flash[:alert] = "Authentication failed. Please try again."
    redirect_to root_path
  end

  private

  def handle_email_login
    user = User.find_by(email: params[:email], provider: nil)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to user_path(user), notice: "Logged in successfully!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new
    end
  end

  def handle_mobile_login
    user = User.find_by_mobile_and_authenticate(params[:mobile_no], params[:password])

    if user
      session[:user_id] = user.id
      redirect_to user_path(user), notice: "Logged in successfully!"
    else
      flash.now[:alert] = "Invalid mobile number or password"
      render :new
    end
  end
end
