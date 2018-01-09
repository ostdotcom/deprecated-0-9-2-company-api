class ApplicationController < ActionController::API

  include ActionController::RequestForgeryProtection
  protect_from_forgery with: :exception

  include CsrfTokenConcern

  [
      ActionController::Cookies
  ].each do |mdl|
    include mdl
  end

  # Sanitize URL params
  include Sanitizer

  before_action :sanitize_params

  after_action :set_response_headers

  def not_found
    r = Result::Base.error({
                               error: 'ac_1',
                               error_message: 'Resource not found',
                               http_code: GlobalConstant::ErrorCode.not_found
                           })
    render_api_response(r)
  end

  private

  def sanitize_params
    sanitize_params_recursively(params)
  end

  def http_user_agent
    # User agent is required for cookie validation
    request.env['HTTP_USER_AGENT'].to_s
  end

  def ip_address
    request.remote_ip.to_s
  end

  def render_api_response(service_response)
    # calling to_json of Result::Base
    response_hash = service_response.to_json
    http_status_code = service_response.http_code

    # filter out not allowed http codes
    http_status_code = GlobalConstant::ErrorCode.ok unless GlobalConstant::ErrorCode.allowed_http_codes.include?(http_status_code)

    # sanitizing out error and data. only display_text and display_heading are allowed to be sent to FE.
    if !service_response.success? && !Rails.env.development?
      err = response_hash.delete(:err) || {}
      response_hash[:err] = {
          display_text: (err[:display_text].to_s),
          display_heading: (err[:display_heading].to_s),
          error_data: (err[:error_data] || {})
      }

      response_hash[:data] = {}
    end

    (render plain: Oj.dump(response_hash, mode: :compat), status: http_status_code)
  end

  def set_response_headers
    response.headers["X-Robots-Tag"] = 'noindex, nofollow'
    response.headers["Content-Type"] = 'application/json; charset=utf-8'
  end

  def delete_cookie(cookie_name)
    cookies.delete(cookie_name.to_sym, domain: :all, secure: !Rails.env.development?, same_site: :strict)
  end

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

end
