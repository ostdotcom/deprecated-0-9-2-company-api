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
      'YFbDp6RgqMvNTKHk8z8BxYJ9QSYQErf2FjMW8Env', # Frankie
      'DjJRQWA8bNdd84xceSNCqjydpf78suLZDYpvPcV7',  # Junisha
      'nVXe6BABW8Bb3n8h43XP8W5nTWm3HgJK2sMPaScH', # PDP
      'rpkYwd3GM2N7dXEkxtRLBwHvhZnVc88R5K8fbKD5', # Jorden
      'Cx74W6GV5fT9drz47kjDvYMqjGaAJxXrjatbwJ3y', # Ignas
      'dF56K5DBC7ZL4CK6gdcQM7gUJPNauAyQwhDfAuAW', # Kevin
      'UzHArPR5C4CbCXZVHMFDbjPuwG2BL4gbrfsThsQE' # Jean
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