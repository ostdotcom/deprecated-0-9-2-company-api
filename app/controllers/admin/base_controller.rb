class Admin::BaseController < WebController
  
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  
  skip_before_action :authenticate_request

  before_action :validate_admin

  private

  def validate_admin
    admins = {
      GlobalConstant::BasicAuth.admin_username => GlobalConstant::BasicAuth.admin_password
    }
    
    admin_secrets = [
      'YFbDp6RgqMvNTKHk8z8BxYJ9QSYQErf2FjMW8Env', # PDP
      'DjJRQWA8bNdd84xceSNCqjydpf78suLZDYpvPcV7'  # Junisha
    ]
  
    authenticate_or_request_with_http_basic do |username, password|
      if admins[username].present? && admins[username] == password && admin_secrets.include?(params[:secret])
        true
      else
        false
      end
    end
    
    Rails.logger.info("Admin request from: #{params[:secret]}(secret)")
  end

end