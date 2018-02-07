class Client::LoginController < Client::BaseController

  unless GlobalConstant::Base.postman_testing?
    before_action :verify_recaptcha, only: [:sign_up, :login]
  end

  before_action :authenticate_request, except: [
    :sign_up,
    :login,
    :logout,
    :send_reset_password_link, :reset_password
  ]

  # Verify Login Cookie
  #
  # * Author: Puneet
  # * Date: 02/02/2018
  # * Reviewed By:
  #
  def verify_cookie
    render_api_response(Result::Base.success({}))
  end

  # Sign up
  #
  # * Author: Alpesh
  # * Date: 15/01/2018
  # * Reviewed By:
  #
  def sign_up
    service_response = UserManagement::SignUp.new(
      params.merge(is_client_manager: 1, client_creation_needed: 1)
    ).perform

    if service_response.success?
      # NOTE: delete cookie value from data
      cookie_value = service_response.data.delete(:cookie_value)
      set_cookie(
        GlobalConstant::Cookie.user_cookie_name,
        cookie_value,
        GlobalConstant::Cookie.user_expiry.from_now
      )
    end

    render_api_response(service_response)
  end

  # Login
  #
  # * Author: Alpesh
  # * Date: 15/01/2018
  # * Reviewed By:
  #
  def login
    service_response = UserManagement::Login.new(params).perform

    if service_response.success?
      # NOTE: delete cookie value from data
      cookie_value = service_response.data.delete(:cookie_value)
      set_cookie(
        GlobalConstant::Cookie.user_cookie_name,
        cookie_value,
        GlobalConstant::Cookie.user_expiry.from_now
      )
    end

    render_api_response(service_response)
  end

  # logout
  #
  # * Author: Puneet
  # * Date: 29/01/2018
  # * Reviewed By:
  #
  def logout
    #TODO: add extra logic if required
    delete_cookie(GlobalConstant::Cookie.user_cookie_name)
    render_api_response(Result::Base.success({}))
  end

  # Send Reset Password link
  #
  # * Author: Pankaj
  # * Date: 15/01/2018
  # * Reviewed By:
  #
  def send_reset_password_link
    service_response = UserManagement::SendResetPasswordLink.new(params).perform
    render_api_response(service_response)
  end

  # Reset Password
  #
  # * Author: Pankaj
  # * Date: 15/01/2018
  # * Reviewed By:
  #
  def reset_password
    service_response = UserManagement::ResetPassword.new(params).perform
    render_api_response(service_response)
  end

  # Email verification of user
  #
  # * Author: Pankaj
  # * Date: 15/01/2018
  # * Reviewed By:
  #
  def verify_email
    service_response = UserManagement::DoubleOptIn.new(params).perform
    render_api_response(service_response)
  end

end
