class SignupsController < ApplicationController
  before_action :set_user, only: [ :show, :update ]
  skip_before_action :require_login, only: [ :new, :create, :show, :update ]

  # Step 1: Account Setup
  def new
    @user = User.new
  end

  def create
    @user = User.new(account_setup_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to signup_step_path(step: 2), notice: "Account created! Now tell us about your background."
    else
      render :new
    end
  end

  # Step 2, 3, 4: Show current step
  def show
    @step = params[:step].to_i
    @step = 2 if @step < 2 || @step > 4
    @progress = (@step / 4.0 * 100).round
  end

  # Update step and move to next
  def update
    @step = params[:step].to_i

    case @step
    when 2
      if @user.update(career_culture_params)
        redirect_to signup_step_path(step: 3), notice: "Profile updated!"
      else
        render :show
      end
    when 3
      if @user.update(lifestyle_params)
        redirect_to signup_step_path(step: 4), notice: "Profile updated!"
      else
        render :show
      end
    when 4
      if @user.update(identity_params)
        redirect_to user_dashboard_path, notice: "Welcome to HoneyMatrimony!"
      else
        render :show
      end
    end
  end

  private

  def set_user
    @user = current_user || User.find_by(id: session[:user_id])
    redirect_to new_signup_path unless @user
  end

  def account_setup_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :gender, :dob)
  end

  def career_culture_params
    params.require(:user).permit(:religion, :mother_tongue, :heighst_education, :job, :organization_name, :annual_income, :address, :highest_educational_details)
  end

  def lifestyle_params
    params.require(:user).permit(:food_type, :hobbies, :alcohol_frequency, :smoking_frequency)
  end

  def identity_params
    params.require(:user).permit(:height, :caste, :manglik, :rashi)
  end
end
