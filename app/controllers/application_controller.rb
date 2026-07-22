class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  helper_method :current_user, :logged_in?, :is_admin?, :is_manager?

  def set_locale_preference
    locale = params[:locale].to_sym
    if I18n.available_locales.include?(locale)
      session[:locale] = locale
      I18n.locale = locale
    end
    redirect_back fallback_location: root_path
  end

  private

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def is_admin?
    logged_in? && current_user.admin?
  end

  def is_manager?
    logged_in? && current_user.manager?
  end

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page"
      redirect_to login_path
    end
  end

  def require_admin
    unless is_admin?
      flash[:alert] = "You do not have permission to access this page"
      redirect_to root_path
    end
  end

  def require_manager_or_admin
    unless is_manager? || is_admin?
      flash[:alert] = "You do not have permission to access this page"
      redirect_to root_path
    end
  end
end
