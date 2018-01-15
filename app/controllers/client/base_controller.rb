class Client::BaseController < WebController

  private

  def authenticate_request
    service_response = UserManagement::VerifyCookie.new(
        cookie_value: cookies[GlobalConstant::Cookie.user_cookie_name.to_sym]
    ).perform

    if service_response.success?
      # Update Cookie, if required
      extended_cookie_value = service_response.data[:extended_cookie_value]
      set_cookie(
          GlobalConstant::Cookie.user_cookie_name,
          extended_cookie_value,
          GlobalConstant::Cookie.user_expiry.from_now
      ) if extended_cookie_value.present?

      # Set user id
      params[:user_id] = service_response.data[:user_id]
      params[:client_id] = service_response.data[:client_id]

      # Remove sensitive data
      service_response.data = {}
    else
      # Clear cookie
      delete_cookie(GlobalConstant::Cookie.user_cookie_name)
      # Set 401 header
      service_response.http_code = GlobalConstant::ErrorCode.unauthorized_access
      render_api_response(service_response)
    end
  end

  def verify_recaptcha
    service_response = Recaptcha::Verify.new({
                                                 'response' => params['g-recaptcha-response'].to_s,
                                                 'remoteip' => request.remote_ip.to_s
                                             }).perform

    Rails.logger.info('---- Recaptcha::Verify done')

    unless service_response.success?
      render_api_response(service_response)
    end

    Rails.logger.info('---- check_recaptcha_before_verification done')

  end

end