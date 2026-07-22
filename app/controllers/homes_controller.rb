class HomesController < ApplicationController
  def index
    # Redirect logged-in users to their dashboard
    if logged_in?
      if current_user.admin? || current_user.manager?
        redirect_to admin_dashboard_path
      else
        redirect_to user_dashboard_path
      end
    else
      # Only show home page for guests
      @user = User.new
    end
  end
end
