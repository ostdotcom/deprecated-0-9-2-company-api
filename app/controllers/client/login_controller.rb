class Client::LoginController < Client::BaseController

  before_action :authenticate_request, except: [
    :sign_up,
    :login
  ]

  before_action :verify_recaptcha, only: [:sign_up, :login]

  def sign_up
    # geo_ip_obj = Util::GeoIpUtil.new(ip_address: ip_address)
    # geoip_country = geo_ip_obj.get_country_name.to_s.downcase

    service_response = UserManagement::SignUp.new(
      params.merge(
        {
          # browser_user_agent: http_user_agent,
          # ip_address: ip_address,
          # geoip_country: geoip_country
        }
      )
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

  def login
    service_response = UserManagement::Login.new(
      params.merge(
        browser_user_agent: http_user_agent,
        ip_address: ip_address
      )
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

  def send_reset_password_link
    service_response = UserManagement::SendResetPasswordLink.new(params).perform
    render_api_response(service_response)
  end

  def reset_password
    service_response = UserManagement::ResetPassword.new(params).perform
    render_api_response(service_response)
  end

end
