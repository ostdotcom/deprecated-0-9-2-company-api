class WebController < ApplicationController

  before_action :append_csrf_token_in_params

  unless GlobalConstant::Base.postman_testing?
    include ActionController::RequestForgeryProtection
    protect_from_forgery with: :exception
    include CsrfTokenConcern
  end

  [
      ActionController::Cookies
  ].each do |mdl|
    include mdl
  end

  # this is the top-most wrapper - to catch all the exceptions at any level
  prepend_around_action :handle_exceptions_gracefully

  before_action :authenticate_request

  def delete_cookie(cookie_name)
    cookies.delete(cookie_name.to_sym, domain: :all, secure: !Rails.env.development?, same_site: :strict)
  end

  # Set cookie
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  # @params [String] cookie_name (mandatory)
  # @params [String] value (mandatory)
  # @params [Time] expires (mandatory)
  #
  def set_cookie(cookie_name, value, expires)
    cookies[cookie_name.to_sym] = {
        value: value,
        expires: expires,
        domain: :all,
        http_only: true,
        secure: !Rails.env.development?,
        same_site: :strict
    }
  end

  private

  # Authenticate request - verifies cookie
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
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

      params[:user_id] = service_response.data[:user_id]
      params[:client_id] = service_response.data[:client_id]
      params[:client_token_id] = service_response.data[:client_token_id]

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

  # Handle exceptions gracefully
  #
  # * Author: Kedar
  # * Date: 24/01/2018
  # * Reviewed By:
  #
  def handle_exceptions_gracefully

    begin

      yield

    rescue => se

      Rails.logger.error("Exception in API: #{se.message}")
      ApplicationMailer.notify(
          body: {exception: {message: se.message, backtrace: se.backtrace}},
          data: {
              'params' => params
          },
          subject: 'Exception in API'
      ).deliver

      r = Result::Base.exception(
        se,
        {
          error: 'swr',
          error_message: 'Something Went Wrong',
          data: params
        }
      )
      render_api_response(r)

    end

  end

  # As FE send authenticity_token in headers set it in params for verification to happen
  #
  # * Author: Puneet
  # * Date: 12/02/2018
  # * Reviewed By:
  #
  def append_csrf_token_in_params
    params[:authenticity_token] = request.headers.env['HTTP_X_CSRF_TOKEN']
  end

end
